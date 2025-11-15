# repo/bench/Desctiptor.py
import os

import numpy as np


DATA = np.asarray(
    np.loadtxt("./data/s5-210.csv", skiprows=1, delimiter=",")
)
X = DATA[:, 0:3]
y = DATA[:, 3]


class Desctiptor:

    def __init__(self):
        self.X = X
        self.y = y

    def get_search_space(self):
        return self.X

    def evaluate(self, idx: np.array):
        return self.y[idx]

    def get_name(self):
        return "Descriptor"

    def get_best_value(self):
        return max(y)

    def get_worst_value(self):
        return min(y)

    def get_regret(self, v):
        return np.abs(v - self.get_best_value())
