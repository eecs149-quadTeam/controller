#!/usr/bin/env python3
"""
    Kobuki randomized path controller.

    (1, 1) is the bottom left/origin and (WIDTH, HEIGHT) is the top right.
"""

import random
import copy
import asyncio
import websockets
import queue
import itertools

from enum import Enum

# Constants
WIDTH = 9
HEIGHT = 6
Q_WIDTH = 3
Q_HEIGHT = 2
ASSETS = list()
NUM_ROBOTS = 1

# Probabilisties
# Probability that the Kobuki enters "explore" mode after finishing all assets
# in a quadrant
P_EXPLORE = 0.33

# Probability that the Kobuki takes an optimal path when navigating to the
# next asset in a quadrant
P_OPTIMAL = 0.5

# Probability that the Kobuki will move to a untraversed location that is the furthest from the
# untraversed location that is closest ot the next asset
P_UNTRAVERSED_FURTHEST = 0.8

ASSET_LIST = [(3, 1), (2, 2), (2, 4), (1, 6), (6, 2), (4, 4), (7, 5), (5, 6), (9, 3), (8, 1)]

class Orientation(Enum):
    N = 0
    E = 1
    S = 2
    W = 3

    # Returns an orientation given an initial location and a next location
    @staticmethod
    def get_orientation(loc1, loc2):
        x1, y1 = loc1
        x2, y2 = loc2

        if x2 > x1:
            return Orientation.E
        elif x2 < x1:
            return Orientation.W
        elif y2 > y1:
            return Orientation.N
        elif y2 < y1:
            return Orientation.S

    def __str__(self):
        if self.value == 0:
            return "NORTH"
        elif self.value == 1:
            return "EAST"
        elif self.value == 2:
            return "SOUTH"
        elif self.value == 3:
            return "WEST"

class RobotState(Enum):
    # Moving from an initial state to the asset in the current quadrant
    LOCAL_PATH_TRAVERSAL = 1

    # Moving to quadrant with next asset
    SWITCH_QUADRANT = 2

    # Exploring the current quadrant after visiting all assets
    EXPLORE = 3

    # Finished exploring all assets
    DONE = 4

    def __str__(self):
        v = self.value
        if v == 1:
            return "LOCAL_PATH_TRAVERSAL"
        elif v == 2:
            return "SWITCH_QUADRANT"
        elif v == 3:
            return "EXPLORE"
        elif v == 4:
            return "DONE"

class Robot:
    def __init__(self,
                 x = 1, y = 1,
                 xg = 1, yg = 1,
                 orientation = Orientation.N,
                 quadrant = 7,
                 state = RobotState.LOCAL_PATH_TRAVERSAL):

        self.x = x
        self.y = y
        self.xg = xg
        self.yg = yg
        self.orientation = orientation
        self.quadrant = quadrant
        self.state = state

        # Traversed locations in local quadrant
        self.traversed = set()

        # List of assets assigned to this robot
        self.assets = list()

        # Copy of assets
        self.assets_copy = list()

        # Next goal location assigned to, generally an asset or virtual asset
        self.next_goal = None

        # Optimal path through all of self.assets
        self.asset_path = list()

        # Path to next asset
        self.path = list()

    def __str__(self):
        return "Robot(x={0}, y={1}, q={2}, xg={3}, yg={4}, state={5})".format(
            self.x, self.y, self.quadrant, self.xg, self.yg, self.state)

    def finished(self):
        return self.state == RobotState.DONE

    # Moves the robot one step
    def move(self):
        if len(self.assets) == 0:
            self.state = RobotState.SWITCH_QUADRANT
            self.assets = list(self.assets_copy)

        if self.state == RobotState.LOCAL_PATH_TRAVERSAL:
            # Take the next step on path to next goal, deciding between the
            # optimal and non-optimal path.
            self.local_path_traversal()
        elif self.state == RobotState.SWITCH_QUADRANT:
            # Take the next step on optimal path to next quadrant.
            self.switch_quadrant()
        elif self.state == RobotState.EXPLORE:
            self.explore()

    def set_loc_global(self, loc_global):
        xg, yg = loc_global
        x, y, q = Grid.global_to_local(loc_global)

        self.x = x
        self.y = y
        self.xg = xg
        self.yg = yg
        self.quadrant = q


    # Assigns a new value to self.path, assumes self.next_goal is set
    def probabilistic_assign_path(self):
        global_loc = (self.xg, self.yg)

        rand = random.random()
        if rand > P_OPTIMAL:
            self.path = Grid.get_shortest_path_global(global_loc, self.next_goal)
            self.path.pop(0)
        else:
            paths = []
            neighbors = Grid.get_local_neighbors((self.x, self.y))
            untraversed_neighbors = neighbors.difference(self.traversed)
            untraversed_neighbors = map(lambda neighbor: Grid.local_to_global(neighbor, self.quadrant), untraversed_neighbors)

            invalid_locs = set(self.traversed)
            invalid_locs.add((self.xg, self.yg))

            for neighbor_loc in untraversed_neighbors:
                paths.append(Grid.get_shortest_path_global(
                    neighbor_loc,
                    self.next_goal,
                    invalid_locs))

            paths = list(filter(None, paths))

            if len(paths) == 0:
                self.path = Grid.get_shortest_path_global(global_loc, self.next_goal)
                self.path.pop(0)
            else:
                max_path = max(paths, key=len)
                max_path_length = len(max_path)

                long_paths = list(filter(lambda path: len(path) == max_path_length, paths))

                # Choose random path if multiple with same length
                if len(long_paths) > 1:
                    rand_index = random.randint(0, len(long_paths) - 1)
                    max_path = long_paths[rand_index]

                self.path = max_path

    def local_path_traversal(self):
        global_loc = (self.xg, self.yg)

        if self.next_goal == global_loc:
            self.assets.pop(0)

            if len(self.assets) == 0:
                self.state = RobotState.SWITCH_QUADRANT
                self.assets = list(self.assets_copy)
                self.switch_quadrant()
                return

        if self.path is None or len(self.path) == 0:
            next_asset = self.assets[0]
            next_asset_quadrant = Grid.get_quadrant(next_asset)

            if next_asset_quadrant != self.quadrant:
                # Done with all assets in this quadrant
                self.next_goal = None
                self.path = list()

                # TODO: Probabilistic on area covered
                rand = random.random()
                if rand < P_EXPLORE and len(self.traversed) < Q_WIDTH * Q_HEIGHT:
                    self.state = RobotState.EXPLORE
                    self.explore()
                else:
                    self.state = RobotState.SWITCH_QUADRANT
                    self.switch_quadrant()

                return
            else:
                # Next asset is in this quadrant
                self.next_goal = next_asset
                self.probabilistic_assign_path()
                # self.path = Grid.get_shortest_path_global(global_loc, self.next_goal)

        next_loc_global = self.path.pop(0)
        self.set_loc_global(next_loc_global)
        self.traversed.add((self.x, self.y))

    # Take the next step on optimal path to next goal/asset.
    # Assumes self.assets is in order.
    def switch_quadrant(self):
        prev_q = self.quadrant
        global_loc = (self.xg, self.yg)

        if self.path is None or len(self.path) == 0:
            # If no path set OR if path is empty:
            # Assign path to next asset (note: assets shouldn't be empty bc check in self.move)
            asset_loc = self.assets[0]
            self.next_goal = asset_loc
            # self.probabilistic_assign_path()
            quadrants = set()

            for asset in self.assets_copy:
                quadrants.add(Grid.get_quadrant(asset))

            self.path = Grid.get_shortest_path_global(global_loc, self.next_goal, quadrants = quadrants)
            self.path.pop(0)

        # Get next location in path to next asset
        next_loc_global = self.path.pop(0)
        self.set_loc_global(next_loc_global)
        self.traversed.add((self.x, self.y))

        # If we've entered a new quadrant, clear self.traversed and switch to
        # LOCAL_PATH_TRAVERSAL
        if prev_q != self.quadrant:
            self.traversed.clear()
            self.traversed.add((self.x, self.y))
            self.path = list()
            self.state = RobotState.LOCAL_PATH_TRAVERSAL

    # Explore the current quadrant
    def explore(self):
        global_loc = (self.xg, self.yg)
        # Get untraversed quadrant locations
        asset_loc = self.assets[0]
        quadrant_locs = Grid.get_quadrant_locs()
        valid_quadrant_locs = quadrant_locs.difference(self.traversed)

        if len(valid_quadrant_locs) == 0:
            self.state = RobotState.SWITCH_QUADRANT
            self.path = list()
            self.next_goal = None
            self.switch_quadrant()
            return

        closest_loc_to_next_asset = min(valid_quadrant_locs, key=lambda loc: Grid.dist(loc, asset_loc))
        closest_loc_local_global = Grid.local_to_global(closest_loc_to_next_asset, self.quadrant)

        if self.path is None or len(self.path) == 0:
            # No goal yet, find point in quadrant closest to next asset
            # from valid_quadrant_locs, find the furthest untraversed location from closest_loc_to_next_asset
            longest_untraversed_local = self.longest(valid_quadrant_locs, closest_loc_to_next_asset)
            longest_untraversed_loc_global = Grid.local_to_global(longest_untraversed_local, self.quadrant)
            rand = random.random()
            if (self.next_goal != closest_loc_local_global and rand < P_UNTRAVERSED_FURTHEST):
                self.next_goal = longest_untraversed_loc_global
            else:
                self.next_goal = closest_loc_local_global

            # self.probabilistic_assign_path()
            self.path = Grid.get_shortest_path_global(global_loc, self.next_goal)
            self.path.pop(0)

        next_loc_global = self.path.pop(0)
        self.set_loc_global(next_loc_global)
        self.traversed.add((self.x, self.y))

        if next_loc_global == self.next_goal and self.next_goal == closest_loc_to_next_asset:
            self.state = RobotState.SWITCH_QUADRANT
            self.path = list()
            self.next_goal = None

    def longest(self, valid_quadrant_locs, closest_loc_to_next_asset):
        return min(valid_quadrant_locs, key= lambda loc: Grid.dist(loc,closest_loc_to_next_asset))

class Grid:
    def __init__(self,
                 width = WIDTH,
                 height = HEIGHT,
                 assets = ASSETS,
                 robots = None):
        self.width = width
        self.height = height
        self.robots = robots
        self.finished = False
        self.traversed = set()

        # Set of (x, y) locations of assets in this Grid
        self.assets = assets

        self.distribute_assets()
        self.compute_asset_paths()
        # self.add_virtual_assets()

    def add_virtual_assets(self):
        for robot in self.robots:
            quadrants = map(lambda asset: Grid.get_quadrant, robot.assets)

            init_loc = (robot.xg, robot.yg)
            init_q = Grid.get_quadrant(init_loc)
            i = 0

            path = [item for sublist in robot.asset_path for item in sublist]
            actual_path = []
            for i in range(1, len(path)):
                if path[i] != path[i - 1]:
                    actual_path.append(path[i - 1])

            actual_path.append(path[len(path) - 1])

    # Distributes self.assets to self.robots by quadrants.
    # There's probably a better way to do this
    def distribute_assets(self):
        for asset_loc in self.assets:
            closest_robot = None
            min_dist = float("inf")
            assigned = False

            for robot in self.robots:
                if asset_loc in robot.assets:
                    assigned = True

            # Stop if asset is already assigned
            if assigned:
                continue

            for robot in self.robots:
                robot_loc = (robot.xg, robot.yg)
                dist = Grid.dist(robot_loc, asset_loc)

                if dist < min_dist or closest_robot is None:
                    min_dist = dist
                    closest_robot = robot

            # Assign asset to closest robot
            closest_robot.assets.append(asset_loc)

            # Additionally assign all assets in that quadrant to the same robot
            asset_quadrant = Grid.get_quadrant(asset_loc)
            for asset in self.assets:
                q = Grid.get_quadrant(asset)

                if q == asset_quadrant and asset != asset_loc:
                    closest_robot.assets.append(asset)

            closest_robot.assets_copy = list(closest_robot.assets)

    # Compute global asset paths for self.robots. Assumes self.robots have
    # been assigned paths.
    def compute_asset_paths(self):
        for robot in self.robots:
            asset_path = list()

            init = (robot.xg, robot.yg)
            for asset_loc in robot.assets:
                next_loc = asset_loc
                asset_path.append(Grid.get_shortest_path_global(init, next_loc))
                init = next_loc

            robot.asset_path = asset_path

    # Moves each of robots in self.robots one step
    def step(self):
        for r in self.robots:
            r.move()

    @staticmethod
    def get_quadrant_locs():
        locs = set()
        for x in range(Q_WIDTH):
            for y in range(Q_HEIGHT):
                locs.add((x + 1, y + 1))

        return locs

    # Returns the quadrant that loc is in.
    @staticmethod
    def get_quadrant(loc):
        x, y = loc
        col = 1 + int((x - 1) / Q_WIDTH)
        row = int((y - 1) / Q_HEIGHT)
        num_rows = int(HEIGHT / Q_HEIGHT)

        return (num_rows - row - 1) * num_rows + col

    # Converts global coords, 0 <= xg <= WIDTH and 0 <= yg <= HEIGHT to local
    # coords for a particular quadrant.
    # Returns x, y, and the quadrant.
    @staticmethod
    def global_to_local_pos(xg, yg):
        row = int(HEIGHT / Q_HEIGHT) - int((yg - 1) / Q_HEIGHT) - 1
        col = int((xg - 1) / Q_WIDTH)

        q = row * int(WIDTH / Q_WIDTH) + col + 1
        x = xg % Q_WIDTH
        y = yg % Q_HEIGHT
        x = Q_WIDTH if x == 0 else x
        y = Q_HEIGHT if y == 0 else y

        return (x, y, q)

    @staticmethod
    def global_to_local(loc):
        return Grid.global_to_local_pos(loc[0], loc[1])

    @staticmethod
    def local_to_global_pos(x, y, quadrant):
        row = int((quadrant - 1) / (HEIGHT / Q_HEIGHT))
        col = int((quadrant - 1) % (WIDTH / Q_WIDTH))

        xg = col * Q_WIDTH + x
        yg = (int(HEIGHT / Q_HEIGHT) - row - 1) * Q_HEIGHT + y

        return (int(xg), int(yg))

    @staticmethod
    def local_to_global(loc, quadrant):
        return Grid.local_to_global_pos(loc[0], loc[1], quadrant)

    @staticmethod
    def get_neighbors(loc, width_bound, height_bound):
        x, y = loc
        neighbors = set()

        if (x < width_bound):
            neighbors.add((x + 1, y))
        if (x > 1):
            neighbors.add((x - 1, y))
        if (y < height_bound):
            neighbors.add((x, y + 1))
        if (y > 1):
            neighbors.add((x, y - 1))

        return neighbors

    # Get set of (x,y) tuples of valid neighbors in current quadrant
    @staticmethod
    def get_local_neighbors(loc):
        return Grid.get_neighbors(loc, Q_WIDTH, Q_HEIGHT)

    @staticmethod
    def get_global_neighbors(loc):
        return Grid.get_neighbors(loc, WIDTH, HEIGHT)

    # Computes the min. Manhattan distance between loc1 and loc2
    @staticmethod
    def dist(loc1, loc2):
        x1, y1 = loc1
        x2, y2 = loc2
        return abs((x2 - x1) + (y2 - y1))

    @staticmethod
    def get_shortest_path_global(loc1, loc2, invalid_locs = set(), quadrants = set()):
        return Grid.get_shortest_path(loc1, loc2, Grid.get_global_neighbors, invalid_locs, quadrants)

    @staticmethod
    def get_shortest_path_local(loc1, loc2, invalid_locs = set(), quadrants = set()):
        return Grid.get_shortest_path(loc1, loc2, Grid.get_local_neighbors, invalid_locs, quadrants)

    # Computes the shortest path from loc2 to loc2.
    # Returns a list of (x, y) tuples or None if no path found
    @staticmethod
    def get_shortest_path(loc1, loc2, neighbor_func, invalid_locs = set(), quadrants = set()):
        x1, y1 = loc1
        x2, y2 = loc2

        q = queue.Queue()
        q.put(loc1)

        visited = set()
        visited.add(loc1)

        parents = dict()

        while not q.empty():
            curr = q.get()
            neighbors = list(neighbor_func(curr))

            for neighbor in neighbors:
                if neighbor not in visited and neighbor not in invalid_locs:
                    if len(quadrants) > 0:
                        if Grid.get_quadrant(neighbor) not in quadrants:
                            continue
                    parents[neighbor] = curr
                    visited.add(neighbor)
                    q.put(neighbor)

                    if neighbor == loc2:
                        result = list()
                        result.append(neighbor)

                        while neighbor in parents:
                            parent = parents[neighbor]
                            result.append(parent)
                            neighbor = parent

                        result.reverse()
                        return result

        return None

r1 = Robot()
r2 = Robot(x = 3, y = 2, xg = 9, yg = 6, orientation = Orientation.S, quadrant = 3)

grid = Grid(
    robots = [r1, r2],
    assets = ASSET_LIST)

@asyncio.coroutine
def send_step():
    init_delay = 3
    ws1 = yield from websockets.connect("ws://localhost:5000")
    ws2 = yield from websockets.connect("ws://localhost:5001")

    print("Beginning simulation in {0} seconds...".format(init_delay))
    print("Asset list: {0}".format(ASSET_LIST))
    print("Initial state of Kobukis:")
    print("R1: {0}".format(r1))
    print("R2: {0}".format(r2))
    print()

    yield from asyncio.sleep(init_delay)

    while r1.state != RobotState.DONE or r2.state != RobotState.DONE:
        r1_loc0 = (r1.xg, r1.yg)
        r2_loc0 = (r2.xg, r2.yg)
        r1_o0 = r1.orientation.value
        r2_o0 = r2.orientation.value

        grid.step()

        r1_loc1 = (r1.xg, r1.yg)
        r2_loc1 = (r2.xg, r2.yg)

        print("R1: {0}".format(r1))
        print("R2: {0}".format(r2))

        if r1_loc0 != r1_loc1 and r2_loc0 != r2_loc1:
            r1.orientation = Orientation.get_orientation(r1_loc0, r1_loc1)
            r2.orientation = Orientation.get_orientation(r2_loc0, r2_loc1)
            r1_o1 = r1.orientation.value
            r2_o1 = r2.orientation.value

            r1_turn_amt = (r1_o1 - r1_o0 + 4) % 4
            r2_turn_amt = (r2_o1 - r2_o0 + 4) % 4

            print("Turning Kobuki #1 " + str(r1_turn_amt * 90) + " deg and moving forward 1 step.")
            print("Turning Kobuki #2 " + str(r2_turn_amt * 90) + " deg and moving forward 1 step.")

            yield from ws1.send(str(r1_turn_amt))
            yield from ws2.send(str(r2_turn_amt))
            # yield from ws1.send(str(r1.xg) + "," + str(r1.yg))
            # yield from ws2.send(str(r2.xg) + "," + str(r2.yg))
            yield from asyncio.sleep(0.4)
        print()

asyncio.get_event_loop().run_until_complete(send_step())

NUM_STEPS = 60
NUM_RUNS = 2000
MAX_NUM_STEPS = 50

def calculate_percentage():
    total = 0.0
    total_steps = 0
    for i in range(NUM_RUNS):
        num_steps = 0

        r1 = Robot()
        grid = Grid(robot=r1)

        while not grid.finished and num_steps < MAX_NUM_STEPS:
            grid.step()
            num_steps += 1

        num_cells = WIDTH * HEIGHT
        num_traversed = len(grid.traversed)
        percent_traversed = num_traversed / num_cells

        print("Run #{0}: % traversed: {1}, # steps: {2}".format(i, percent_traversed, num_steps))
        total += percent_traversed
        total_steps += num_steps

    return (total / NUM_RUNS, total_steps / NUM_RUNS)

def calculate_area_coverage():
    r1 = Robot()
    r2 = Robot(x = 3, y = 2, xg = 9, yg = 6, orientation = Orientation.S, quadrant = 3)

    grid = Grid(
        robots = [r1, r2],
        assets = ASSET_LIST)

    for i in range(NUM_STEPS):
        r1 = Robot()

#avg_percent, avg_steps = calculate_percentage()
#print("For {0} runs, avg. % traversed: {1}, avg. # steps: {2}".format(NUM_RUNS, avg_percent, avg_steps));

