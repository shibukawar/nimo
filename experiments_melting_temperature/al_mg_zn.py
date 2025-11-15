# repo/bench/al_mg_zn.py
import os

import numpy as np

DATA = np.asarray(
    np.loadtxt("data/mp_al-mg-zn.csv", skiprows=0, delimiter=",")
)
X = DATA[:, 0:2]
y = DATA[:, 2]


class AlMgZnMeltingPoint():

    def __init__(self):
        self.X = X
        self.y = y

    def get_search_space(self):
        return self.X

    def evaluate(self, idx: np.array):
        return self.y[idx]

    def get_name(self):
        return "Al-Mg-Zn melting point"

    def get_best_value(self):
        return max(y)

    def get_worst_value(self):
        return min(y)

    def get_regret(self, v):
        return np.abs(v - self.get_best_value())
