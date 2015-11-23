"""
    Kobuki randomized path controller.

    (1, 1) is the bottom left/origin and (WIDTH, HEIGHT) is the top right.
"""

import random
import copy
from enum import Enum

# Constants
TRAN1 = 2
TRAN2 = 3
TRAN1_2 = 4
QUADRANT1 = 1
QUADRANT2 = 2
QUADRANT3 = 3
QUADRANT4 = 4
QUADRANT_NEIGHBORS = {
    QUADRANT1: set([QUADRANT2, QUADRANT3]),
    QUADRANT2: set([QUADRANT1, QUADRANT4]),
    QUADRANT3: set([QUADRANT1, QUADRANT4]),
    QUADRANT4: set([QUADRANT2, QUADRANT3])
}
WIDTH = 6
HEIGHT = 6
Q_AREA = WIDTH / 2 * HEIGHT / 2
NUM_ROBOTS = 1
NUM_STEPS = 100

class Orientation(Enum):
    N = 1
    E = 2
    S = 3
    W = 4

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

class RobotState(Enum):
    STABLE = 1
    TRANSITIONING = 2

class Robot:
    def __init__(self, x=1, y=1, xg=1, yg=1, orientation=Orientation.N, quadrant=QUADRANT3, state=RobotState.STABLE):
        self.x = x
        self.y = y
        self.xg = xg
        self.yg = yg
        self.orientation = orientation
        self.quadrant = quadrant
        self.state = state
        self.traversed = set()
        self.traversed_quadrants = set()

        # Previous two states of this Robot, for look-ahead
        self.prev_states = list()

    def __str__(self):
        return "Robot(x=" + str(self.x) + ", y=" + str(self.y) + ", q=" + str(self.quadrant) + ")"

    # Returns true if moving this Robot to (x, y) will cause it to be blocked
    # on all sides.
    def will_block(self, x, y, traversed):
        return len(traversed) == Q_AREA - 1

    def is_blocked(self):
        return len(self.traversed) == Q_AREA - 1

    # Returns true if my current position and quadrant makes switching into a
    # new quadrant a valid move
    # switch_quadrant_possible
    def can_switch_quadrant(self):
        q = self.quadrant
        x = self.x
        y = self.y

        if q == QUADRANT1:
            return x == 3 or y == 1
        elif q == QUADRANT2:
            return x == 1 or y == 1
        elif q == QUADRANT3:
            return x == 3 or y == 3
        elif q == QUADRANT4:
            return x == 1 or y == 3

    # Returns new (x, y), quadrant, and orientation from current x, y, and quadrant
    def switch_nearest_quadrant(self):
        q = self.quadrant
        x = self.x
        y = self.y

        q_new = self.get_next_quadrant()
        x_new, y_new, o_new = x, y, self.orientation
        if q == QUADRANT1:
            if q_new == QUADRANT2:
                x_new = 1
                y_new = y
                o_new = Orientation.E
            elif q_new == QUADRANT3:
                x_new = x
                y_new = 3
                o_new = Orientation.S
        elif q == QUADRANT2:
            if q_new == QUADRANT1:
                x_new = 3
                y_new = y
                o_new = Orientation.W
            elif q_new == QUADRANT4:
                x_new = x
                y_new = 3
                o_new = Orientation.S
        elif q == QUADRANT3:
            if q_new == QUADRANT4:
                x_new = 1
                y_new = y
                o_new = Orientation.E
            elif q_new == QUADRANT1:
                x_new = x
                y_new = 1
                o_new = Orientation.N
        elif q == QUADRANT4:
            if q_new == QUADRANT3:
                x_new = 3
                y_new = y
                o_new = Orientation.W
            elif q_new == QUADRANT2:
                x_new = x
                y_new = 1
                o_new = Orientation.N

        return (x_new, y_new, o_new, q_new)

    # Returns new quadrant based on location. Assumes current (x, y) is on the
    # edge of the current quadrant.
    # Randomly chooses between two neighboring quadrants if at a corner.
    def get_next_quadrant(self):
        q = self.quadrant
        x = self.x
        y = self.y
        rand = random.random()

        if q == QUADRANT1:
            if x == 3 and y == 1:
                return QUADRANT2 if rand > 0.5 else QUADRANT3
            elif x == 3:
                return QUADRANT2
            elif y == 1:
                return QUADRANT1
        elif q == QUADRANT2:
            if x == 1 and y == 1:
                return QUADRANT1 if rand > 0.5 else QUADRANT4
            elif x == 1:
                return QUADRANT1
            elif y == 1:
                return QUADRANT4
        elif q == QUADRANT3:
            if x == 3 and y == 3:
                return QUADRANT1 if rand > 0.5 else QUADRANT4
            elif x == 3:
                return QUADRANT4
            elif y == 3:
                return QUADRANT1
        elif q == QUADRANT4:
            if x == 1 and y == 3:
                return QUADRANT2 if rand > 0.5 else QUADRANT3
            elif x == 1:
                return QUADRANT3
            elif y == 3:
                return QUADRANT2

    # Return a Set of all untraversed neighboring quadrants
    def get_untraversed_neighbor_quadrants(self):
        q = self.quadrant
        neighbors = QUADRANT_NEIGHBORS[q]
        return neighbors.difference(self.traversed_quadrants)

    # Returns the next location given my current orientation
    def get_next_location(self):
        o = self.orientation
        x_new, y_new = self.x, self.y

        if o == Orientation.N:
            y_new += 1
        elif o == Orientation.E:
            x_new += 1
        elif o == Orientation.S:
            y_new -= 1
        elif o == Orientation.W:
            x_new -= 1

        return (x_new, y_new)

    def copy_state(self, robot):
        self.x = robot.x
        self.y = robot.y
        self.traversed = robot.traversed
        self.orientation = robot.orientation
        self.quadrant = robot.quadrant

    # Get set of (x,y) tuples of valid neighbors in current quadrant
    def get_local_neighbors(self):
        q_width = WIDTH / 2
        q_height = HEIGHT / 2
        neighbors = set()

        if (self.x < q_width):
            neighbors.add((self.x + 1, self.y))
        if (self.x > 1):
            neighbors.add((self.x - 1, self.y))
        if (self.y < q_height):
            neighbors.add((self.x, self.y + 1))
        if (self.y > 1):
            neighbors.add((self.x, self.y - 1))

        return neighbors

    # Moves the robot one step
    def move(self):
        if self.state == RobotState.STABLE:
            if self.is_blocked():
                # Currently blocked
                print("blocked")

                prev_q = self.quadrant
                self.state = RobotState.TRANSITIONING
                self.next_location() # moves to next location
                self.traversed.clear()
                if self.quadrant != prev_q:
                    self.state = RobotState.STABLE
            else:
                # Get next location and next next location
                # One of next two locations will block
                next = copy.copy(self)
                next.move_within_quadrant()
                next_next = copy.copy(next)
                next_next.move_within_quadrant()

                if not next_next.is_blocked():
                    self.copy_state(next)
                elif next.is_blocked() or next_next.is_blocked():
                    # If going to be blocked, move quadrants
                    if self.can_switch_quadrant():
                        self.copy_state(next)
                    else:
                        # If going to be blocked and can't switch quadrants, switch then reset traversed
                        x_new, y_new, o_new, q_new = self.switch_nearest_quadrant()
                        self.x = x_new
                        self.y = y_new
                        self.orientation = o_new
                        self.quadrant = q_new
                        self.traversed.clear()
        elif self.state == RobotState.TRANSITIONING:
            prev_q = self.quadrant
            self.next_location()
            self.traversed.clear()

            if self.quadrant != prev_q:
                self.state = RobotState.STABLE

        # Update global coords
        self.xg, self.yg = Grid.local_to_global(self.x, self.y, self.quadrant)

    # next_location
    def next_location(self):
        if self.can_switch_quadrant():
            self.move_to_nearest_quadrant()
        else:
            self.move_towards_quadrant()

    # Moves the robot within it's current quadrant, like sub_controller
    def move_within_quadrant(self):
        rand = random.random() * 100
        rand_dir = random.random() * 100
        neighbors = self.get_local_neighbors()

        self.traversed.add((self.x, self.y))
        print(self.traversed)

        if rand > 100:
            # TODO: Choose traversed locations that are neighbors of current location
            print("hm")
        else:
            untraversed_neighbors = neighbors.difference(self.traversed)

            # next location if going straight
            next_straight_loc = self.get_next_location()
            non_straight_neighbors = untraversed_neighbors.copy()
            non_straight_neighbors.discard(next_straight_loc)

            if len(untraversed_neighbors) == 0:
                if next_straight_loc in neighbors:
                    self.x, self.y = next_straight_loc
                else:
                    # Choose random neighbor
                    index = 0 if len(neighbors) == 0 else random.randint(0, len(neighbors) - 1)
                    n = list(neighbors)[index]

                    self.orientation = Orientation.get_orientation((self.x, self.y), n)
                    self.x, self.y = n
            else:
                if rand_dir <= 90 and next_straight_loc in untraversed_neighbors:
                    self.x, self.y = next_straight_loc
                elif len(non_straight_neighbors) > 0:
                    index = 0 if len(non_straight_neighbors) == 0 else random.randint(0, len(non_straight_neighbors) - 1)
                    n = list(non_straight_neighbors)[index]

                    self.orientation = Orientation.get_orientation((self.x, self.y), n)
                    self.x, self.y = n
                else:
                    self.x, self.y = next_straight_loc

    # Move one step towards the nearest quadrant
    # same as next_location
    def move_to_nearest_quadrant(self):
        q = self.quadrant
        x = self.x
        y = self.y
        untraversed_neighbor_quadrants = self.get_untraversed_neighbor_quadrants()
        neighbor_quadrant = list(untraversed_neighbor_quadrants)[0]
        x_new, y_new, o_new, q_new = self.switch_nearest_quadrant()

        if q_new in self.traversed_quadrants:
            # If quadrant we're trying to go to has been traversed,
            # we might need to traverse over already traversed quadrant
            if q == QUADRANT1:
                if neighbor_quadrant == QUADRANT2:
                    x_new = x + 1
                    y_new = y + 1
                    o_new = Orientation.E
                    q_new = QUADRANT1
                else:
                    x_new = x
                    y_new = y - 1
                    o_new = Orientation.S
                    q_new = QUADRANT1
            elif q == QUADRANT2:
                if neighbor_quadrant == QUADRANT1:
                    x_new = x - 1
                    y_new = y
                    o_new = Orientation.W
                    q_new = QUADRANT2
                else:
                    x_new = x
                    y_new = y - 1
                    o_new = Orientation.S
                    q_new = QUADRANT2
            elif q == QUADRANT3:
                if neighbor_quadrant == QUADRANT4:
                    x_new = x + 1
                    y_new = y
                    o_new = Orientation.E
                    q_new = QUADRANT3
                else:
                    x_new = x
                    y_new = y + 1
                    o_new = Orientation.N
                    q_new = QUADRANT3
            elif q == QUADRANT4:
                if neighbor_quadrant == QUADRANT3:
                    x_new = x - 1
                    y_new = y
                    o_new = Orientation.W
                    q_new = QUADRANT4
                else:
                    x_new = x
                    y_new = y + 1
                    o_new = Orientation.N
                    q_new = QUADRANT4

        self.x = x_new
        self.y = y_new
        self.orientation = o_new
        self.quadrant = q_new


    def move_towards_quadrant(self):
        q = self.quadrant
        x = self.x
        y = self.y
        untraversed_neighbor_quadrants = self.get_untraversed_neighbor_quadrants()
        neighbor_quadrant = list(untraversed_neighbor_quadrants)[0]
        x_new, y_new, o_new, q_new = x, y, self.orientation, q

        if q == QUADRANT1:
            if len(untraversed_neighbor_quadrants) == 2:
                if y == 3:
                    x_new = x + 1
                    y_new = y
                    o_new = Orientation.E
                    q_new = QUADRANT1
                else:
                    x_new = x
                    y_new = y - 1
                    o_new = Orientation.S
                    q_new = QUADRANT1
            elif neighbor_quadrant == QUADRANT2:
                x_new = x + 1
                y_new = y
                o_new = Orientation.E
                q_new = QUADRANT1
            else:
                x_new = x
                y_new = y - 1
                o_new = Orientation.S
                q_new = QUADRANT1
        if q == QUADRANT2:
            if len(untraversed_neighbor_quadrants) == 2:
                if y == 3:
                    x_new = x - 1
                    y_new = y
                    o_new = Orientation.W
                    q_new = QUADRANT2
                else:
                    x_new = x
                    y_new = y - 1
                    o_new = Orientation.S
                    q_new = QUADRANT2
            elif neighbor_quadrant == QUADRANT1:
                x_new = x - 1
                y_new = y
                o_new = Orientation.W
                q_new = QUADRANT2
            else:
                x_new = x
                y_new = y - 1
                o_new = Orientation.S
                q_new = QUADRANT2
        if q == QUADRANT3:
            if len(untraversed_neighbor_quadrants) == 2:
                if y == 1:
                    x_new = x + 1
                    y_new = y
                    o_new = Orientation.S
                    q_new = QUADRANT3
                else:
                    x_new = x
                    y_new = y + 1
                    o_new = Orientation.N
                    q_new = QUADRANT3
            elif neighbor_quadrant == QUADRANT4:
                x_new = x + 1
                y_new = y
                o_new = Orientation.S
                q_new = QUADRANT3
            else:
                x_new = x
                y_new = y + 1
                o_new = Orientation.N
                q_new = QUADRANT3
        if q == QUADRANT4:
            if len(untraversed_neighbor_quadrants) == 2:
                if y == 1:
                    x_new = x - 1
                    y_new = y
                    o_new = Orientation.W
                    q_new = QUADRANT4
                else:
                    x_new = x
                    y_new = y + 1
                    o_new = Orientation.N
                    q_new = QUADRANT4
            elif neighbor_quadrant == QUADRANT3:
                x_new = x - 1
                y_new = y
                o_new = Orientation.W
                q_new = QUADRANT4
            else:
                x_new = x
                y_new = y + 1
                o_new = Orientation.N
                q_new = QUADRANT4


        self.x = x_new
        self.y = y_new
        self.orientation = o_new
        self.quadrant = q_new

class Grid:
    def __init__(self, width=WIDTH, height=HEIGHT, robot=None):
        self.width = width
        self.height = height
        self.robot = robot

    # Moves each of robots in self.robots one step
    # Currently assumes only one robot
    # TODO: Implement multiple robot movement
    def step(self):
        r = self.robot

        r.traversed_quadrants.add(r.quadrant)
        if len(r.traversed_quadrants) >= 4:
            r.traversed_quadrants.clear()

        print(r)
        r.move()


    # Converts global coords, 0 <= xg <= WIDTH and 0 <= yg <= HEIGHT to local
    # coords for a particular quadrant.
    # Returns x, y, and the quadrant.
    @staticmethod
    def global_to_local(xg, yg):
        x, y, quadrant = xg, yg, QUADRANT3
        x_mid, y_mid = self.width / 2, self.height / 2
        if xg < x_mid:
            if yg < y_mid:
                x = xg
                y = yg
                quadrant = QUADRANT3
            else:
                x = xg
                y = yg - y_mid
                quadrant = QUADRANT1
        else:
            if yg < self.height / 2:
                x = xg - x_mid
                y = yg
                quadrant = QUADRANT4
            else:
                x = xg - x_mid
                y = yg - y_mid
                quadrant = QUADRANT2
        return (x, y, quadrant)

    @staticmethod
    def local_to_global(x, y, quadrant):
        xg, yg = x, y
        x_mid = WIDTH / 2
        y_mid = HEIGHT / 2

        # Don't need to modify for Q1
        if quadrant == QUADRANT4:
            xg += x_mid
        elif quadrant == QUADRANT3:
            yg += y_mid
        elif quadrant == QUADRANT4:
            xg += x_mid
            yg += y_mid

        return (xg, yg)

r1 = Robot()
grid = Grid(robot=r1)

for i in range(NUM_STEPS):
    grid.step()

