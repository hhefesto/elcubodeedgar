# The proofs of LAWS.bend. Every law here is about finitely many moves, and
# each is proven by computation: a case for each face (and turn), where both
# sides compute to the same cube, so {==} closes it (ru_order in pieces, see
# there). Nothing here is trusted: `bend PROOF.bend` checks every def, and
# `bend PROOF.bend --verdict` checks them again with BendTT's kernel.

import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Group.bend as G
import ./Guard.bend as Gd
import ./LAWS.bend as Laws

def Laws.quarter_turn_order(f):
  match f:
    case G.FU{}:
      {==}
    case G.FR{}:
      {==}
    case G.FF{}:
      {==}
    case G.FD{}:
      {==}
    case G.FL{}:
      {==}
    case G.FB{}:
      {==}

def Laws.move_then_inverse(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.same_face_merge(f, t, u):
  match f t u:
    case G.FU{} G.TQ{} G.TQ{}:
      {==}
    case G.FU{} G.TQ{} G.TH{}:
      {==}
    case G.FU{} G.TQ{} G.TI{}:
      {==}
    case G.FU{} G.TH{} G.TQ{}:
      {==}
    case G.FU{} G.TH{} G.TH{}:
      {==}
    case G.FU{} G.TH{} G.TI{}:
      {==}
    case G.FU{} G.TI{} G.TQ{}:
      {==}
    case G.FU{} G.TI{} G.TH{}:
      {==}
    case G.FU{} G.TI{} G.TI{}:
      {==}
    case G.FR{} G.TQ{} G.TQ{}:
      {==}
    case G.FR{} G.TQ{} G.TH{}:
      {==}
    case G.FR{} G.TQ{} G.TI{}:
      {==}
    case G.FR{} G.TH{} G.TQ{}:
      {==}
    case G.FR{} G.TH{} G.TH{}:
      {==}
    case G.FR{} G.TH{} G.TI{}:
      {==}
    case G.FR{} G.TI{} G.TQ{}:
      {==}
    case G.FR{} G.TI{} G.TH{}:
      {==}
    case G.FR{} G.TI{} G.TI{}:
      {==}
    case G.FF{} G.TQ{} G.TQ{}:
      {==}
    case G.FF{} G.TQ{} G.TH{}:
      {==}
    case G.FF{} G.TQ{} G.TI{}:
      {==}
    case G.FF{} G.TH{} G.TQ{}:
      {==}
    case G.FF{} G.TH{} G.TH{}:
      {==}
    case G.FF{} G.TH{} G.TI{}:
      {==}
    case G.FF{} G.TI{} G.TQ{}:
      {==}
    case G.FF{} G.TI{} G.TH{}:
      {==}
    case G.FF{} G.TI{} G.TI{}:
      {==}
    case G.FD{} G.TQ{} G.TQ{}:
      {==}
    case G.FD{} G.TQ{} G.TH{}:
      {==}
    case G.FD{} G.TQ{} G.TI{}:
      {==}
    case G.FD{} G.TH{} G.TQ{}:
      {==}
    case G.FD{} G.TH{} G.TH{}:
      {==}
    case G.FD{} G.TH{} G.TI{}:
      {==}
    case G.FD{} G.TI{} G.TQ{}:
      {==}
    case G.FD{} G.TI{} G.TH{}:
      {==}
    case G.FD{} G.TI{} G.TI{}:
      {==}
    case G.FL{} G.TQ{} G.TQ{}:
      {==}
    case G.FL{} G.TQ{} G.TH{}:
      {==}
    case G.FL{} G.TQ{} G.TI{}:
      {==}
    case G.FL{} G.TH{} G.TQ{}:
      {==}
    case G.FL{} G.TH{} G.TH{}:
      {==}
    case G.FL{} G.TH{} G.TI{}:
      {==}
    case G.FL{} G.TI{} G.TQ{}:
      {==}
    case G.FL{} G.TI{} G.TH{}:
      {==}
    case G.FL{} G.TI{} G.TI{}:
      {==}
    case G.FB{} G.TQ{} G.TQ{}:
      {==}
    case G.FB{} G.TQ{} G.TH{}:
      {==}
    case G.FB{} G.TQ{} G.TI{}:
      {==}
    case G.FB{} G.TH{} G.TQ{}:
      {==}
    case G.FB{} G.TH{} G.TH{}:
      {==}
    case G.FB{} G.TH{} G.TI{}:
      {==}
    case G.FB{} G.TI{} G.TQ{}:
      {==}
    case G.FB{} G.TI{} G.TH{}:
      {==}
    case G.FB{} G.TI{} G.TI{}:
      {==}

def Laws.opposite_commute(f, t, u):
  match f t u:
    case G.FU{} G.TQ{} G.TQ{}:
      {==}
    case G.FU{} G.TQ{} G.TH{}:
      {==}
    case G.FU{} G.TQ{} G.TI{}:
      {==}
    case G.FU{} G.TH{} G.TQ{}:
      {==}
    case G.FU{} G.TH{} G.TH{}:
      {==}
    case G.FU{} G.TH{} G.TI{}:
      {==}
    case G.FU{} G.TI{} G.TQ{}:
      {==}
    case G.FU{} G.TI{} G.TH{}:
      {==}
    case G.FU{} G.TI{} G.TI{}:
      {==}
    case G.FR{} G.TQ{} G.TQ{}:
      {==}
    case G.FR{} G.TQ{} G.TH{}:
      {==}
    case G.FR{} G.TQ{} G.TI{}:
      {==}
    case G.FR{} G.TH{} G.TQ{}:
      {==}
    case G.FR{} G.TH{} G.TH{}:
      {==}
    case G.FR{} G.TH{} G.TI{}:
      {==}
    case G.FR{} G.TI{} G.TQ{}:
      {==}
    case G.FR{} G.TI{} G.TH{}:
      {==}
    case G.FR{} G.TI{} G.TI{}:
      {==}
    case G.FF{} G.TQ{} G.TQ{}:
      {==}
    case G.FF{} G.TQ{} G.TH{}:
      {==}
    case G.FF{} G.TQ{} G.TI{}:
      {==}
    case G.FF{} G.TH{} G.TQ{}:
      {==}
    case G.FF{} G.TH{} G.TH{}:
      {==}
    case G.FF{} G.TH{} G.TI{}:
      {==}
    case G.FF{} G.TI{} G.TQ{}:
      {==}
    case G.FF{} G.TI{} G.TH{}:
      {==}
    case G.FF{} G.TI{} G.TI{}:
      {==}
    case G.FD{} G.TQ{} G.TQ{}:
      {==}
    case G.FD{} G.TQ{} G.TH{}:
      {==}
    case G.FD{} G.TQ{} G.TI{}:
      {==}
    case G.FD{} G.TH{} G.TQ{}:
      {==}
    case G.FD{} G.TH{} G.TH{}:
      {==}
    case G.FD{} G.TH{} G.TI{}:
      {==}
    case G.FD{} G.TI{} G.TQ{}:
      {==}
    case G.FD{} G.TI{} G.TH{}:
      {==}
    case G.FD{} G.TI{} G.TI{}:
      {==}
    case G.FL{} G.TQ{} G.TQ{}:
      {==}
    case G.FL{} G.TQ{} G.TH{}:
      {==}
    case G.FL{} G.TQ{} G.TI{}:
      {==}
    case G.FL{} G.TH{} G.TQ{}:
      {==}
    case G.FL{} G.TH{} G.TH{}:
      {==}
    case G.FL{} G.TH{} G.TI{}:
      {==}
    case G.FL{} G.TI{} G.TQ{}:
      {==}
    case G.FL{} G.TI{} G.TH{}:
      {==}
    case G.FL{} G.TI{} G.TI{}:
      {==}
    case G.FB{} G.TQ{} G.TQ{}:
      {==}
    case G.FB{} G.TQ{} G.TH{}:
      {==}
    case G.FB{} G.TQ{} G.TI{}:
      {==}
    case G.FB{} G.TH{} G.TQ{}:
      {==}
    case G.FB{} G.TH{} G.TH{}:
      {==}
    case G.FB{} G.TH{} G.TI{}:
      {==}
    case G.FB{} G.TI{} G.TQ{}:
      {==}
    case G.FB{} G.TI{} G.TH{}:
      {==}
    case G.FB{} G.TI{} G.TI{}:
      {==}

def Laws.not_abelian():
  {==}

def Laws.move_twist(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.move_flip(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.move_parity(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.sexy_order():
  {==}

# (R U)^105 at once is more computing than BendTT's kernel (`--verdict`) gives
# one def, so it goes in seven pieces of fifteen turns: (R U)^15k is a cube whose
# corners are home (their cycles have orders 3 and 5) and whose edges are on a
# 7-cycle, written out below, and each piece is fifteen turns from the last.
# Three small lemmas, by induction, join the pieces.

# a cube with its corners home and unturned and its edges at ep, unflipped
def pf.edges(+ep: List<&2, U32>) -> C.Cube:
  C.Cube{[0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0], ep, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}

# (R U)^15, ^30, ^45, ^60, ^75, ^90
def pf.ru15() -> C.Cube:
  pf.edges([3, 8, 1, 2, 11, 5, 6, 7, 4, 9, 10, 0])

def pf.ru30() -> C.Cube:
  pf.edges([2, 4, 8, 1, 0, 5, 6, 7, 11, 9, 10, 3])

def pf.ru45() -> C.Cube:
  pf.edges([1, 11, 4, 8, 3, 5, 6, 7, 0, 9, 10, 2])

def pf.ru60() -> C.Cube:
  pf.edges([8, 0, 11, 4, 2, 5, 6, 7, 3, 9, 10, 1])

def pf.ru75() -> C.Cube:
  pf.edges([4, 3, 0, 11, 1, 5, 6, 7, 2, 9, 10, 8])

def pf.ru90() -> C.Cube:
  pf.edges([11, 2, 3, 0, 8, 5, 6, 7, 1, 9, 10, 4])

# one more c after p of them is c after s, p + 1 times
def pf.iter_step(p: Nat, +c: C.Cube, +s: C.Cube) -> {G.gr.iter(1n+p, c, s) == C.cube.mul(G.gr.iter(p, c, s), c) : C.Cube}:
  match p:
    case 0n:
      {==}
    case 1n+q:
      pf.iter_step(q, c, C.cube.mul(s, c))

# c^n is c n times after solved
def pf.pow_iter(+c: C.Cube, n: Nat) -> {G.gr.iter(n, c, C.cube.solved()) == C.cube.pow(c, n) : C.Cube}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %pf.pow_iter(c, p) : {G.gr.iter(1n+p, c, C.cube.solved()) == C.cube.mul(_, c) : C.Cube}
      pf.iter_step(p, c, C.cube.solved())

# a times, then b times, is a + b times
def pf.iter_add(a: Nat, -b: Nat, +c: C.Cube, +s: C.Cube) -> {G.gr.iter(b, c, G.gr.iter(a, c, s)) == G.gr.iter(Nat.add(a, b), c, s) : C.Cube}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      pf.iter_add(p, b, c, C.cube.mul(s, c))

# each piece: fifteen turns of R U from the last
def pf.k15() -> {pf.ru15() == G.gr.iter(15n, G.gr.ru(), C.cube.solved()) : C.Cube}:
  {==}

def pf.k30() -> {pf.ru30() == G.gr.iter(15n, G.gr.ru(), pf.ru15()) : C.Cube}:
  {==}

def pf.k45() -> {pf.ru45() == G.gr.iter(15n, G.gr.ru(), pf.ru30()) : C.Cube}:
  {==}

def pf.k60() -> {pf.ru60() == G.gr.iter(15n, G.gr.ru(), pf.ru45()) : C.Cube}:
  {==}

def pf.k75() -> {pf.ru75() == G.gr.iter(15n, G.gr.ru(), pf.ru60()) : C.Cube}:
  {==}

def pf.k90() -> {pf.ru90() == G.gr.iter(15n, G.gr.ru(), pf.ru75()) : C.Cube}:
  {==}

# the sums the pieces take: 105 = 15 + 90, 90 = 15 + 75, ..., 30 = 15 + 15
def pf.n105() -> {Nat.add(15n, 90n) == 105n : Nat}:
  {==}

def pf.n90() -> {Nat.add(15n, 75n) == 90n : Nat}:
  {==}

def pf.n75() -> {Nat.add(15n, 60n) == 75n : Nat}:
  {==}

def pf.n60() -> {Nat.add(15n, 45n) == 60n : Nat}:
  {==}

def pf.n45() -> {Nat.add(15n, 30n) == 45n : Nat}:
  {==}

def pf.n30() -> {Nat.add(15n, 15n) == 30n : Nat}:
  {==}

def Laws.ru_order():
  %pf.pow_iter(G.gr.ru(), 105n) : {_ == C.cube.solved() : C.Cube}
  %pf.n105() : {G.gr.iter(_, G.gr.ru(), C.cube.solved()) == C.cube.solved() : C.Cube}
  %pf.iter_add(15n, 90n, G.gr.ru(), C.cube.solved()) : {_ == C.cube.solved() : C.Cube}
  %pf.k15() : {G.gr.iter(90n, G.gr.ru(), _) == C.cube.solved() : C.Cube}
  %pf.n90() : {G.gr.iter(_, G.gr.ru(), pf.ru15()) == C.cube.solved() : C.Cube}
  %pf.iter_add(15n, 75n, G.gr.ru(), pf.ru15()) : {_ == C.cube.solved() : C.Cube}
  %pf.k30() : {G.gr.iter(75n, G.gr.ru(), _) == C.cube.solved() : C.Cube}
  %pf.n75() : {G.gr.iter(_, G.gr.ru(), pf.ru30()) == C.cube.solved() : C.Cube}
  %pf.iter_add(15n, 60n, G.gr.ru(), pf.ru30()) : {_ == C.cube.solved() : C.Cube}
  %pf.k45() : {G.gr.iter(60n, G.gr.ru(), _) == C.cube.solved() : C.Cube}
  %pf.n60() : {G.gr.iter(_, G.gr.ru(), pf.ru45()) == C.cube.solved() : C.Cube}
  %pf.iter_add(15n, 45n, G.gr.ru(), pf.ru45()) : {_ == C.cube.solved() : C.Cube}
  %pf.k60() : {G.gr.iter(45n, G.gr.ru(), _) == C.cube.solved() : C.Cube}
  %pf.n45() : {G.gr.iter(_, G.gr.ru(), pf.ru60()) == C.cube.solved() : C.Cube}
  %pf.iter_add(15n, 30n, G.gr.ru(), pf.ru60()) : {_ == C.cube.solved() : C.Cube}
  %pf.k75() : {G.gr.iter(30n, G.gr.ru(), _) == C.cube.solved() : C.Cube}
  %pf.n30() : {G.gr.iter(_, G.gr.ru(), pf.ru75()) == C.cube.solved() : C.Cube}
  %pf.iter_add(15n, 15n, G.gr.ru(), pf.ru75()) : {_ == C.cube.solved() : C.Cube}
  %pf.k90() : {G.gr.iter(15n, G.gr.ru(), _) == C.cube.solved() : C.Cube}
  {==}

def Laws.search_face(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.search_not_same_face(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.search_one_order(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}


def Laws.search_first(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.read_solved():
  {==}

def Laws.read_move(f, t):
  match f t:
    case G.FU{} G.TQ{}:
      {==}
    case G.FU{} G.TH{}:
      {==}
    case G.FU{} G.TI{}:
      {==}
    case G.FR{} G.TQ{}:
      {==}
    case G.FR{} G.TH{}:
      {==}
    case G.FR{} G.TI{}:
      {==}
    case G.FF{} G.TQ{}:
      {==}
    case G.FF{} G.TH{}:
      {==}
    case G.FF{} G.TI{}:
      {==}
    case G.FD{} G.TQ{}:
      {==}
    case G.FD{} G.TH{}:
      {==}
    case G.FD{} G.TI{}:
      {==}
    case G.FL{} G.TQ{}:
      {==}
    case G.FL{} G.TH{}:
      {==}
    case G.FL{} G.TI{}:
      {==}
    case G.FB{} G.TQ{}:
      {==}
    case G.FB{} G.TH{}:
      {==}
    case G.FB{} G.TI{}:
      {==}

def Laws.read_superflip():
  {==}

def Laws.read_hand23():
  {==}

def Laws.refuse_twisted(p):
  match p:
    case Gd.CURF{}:
      {==}
    case Gd.CUFL{}:
      {==}
    case Gd.CULB{}:
      {==}
    case Gd.CUBR{}:
      {==}
    case Gd.CDFR{}:
      {==}
    case Gd.CDLF{}:
      {==}
    case Gd.CDBL{}:
      {==}
    case Gd.CDRB{}:
      {==}

def Laws.refuse_corners_swapped(p):
  match p:
    case Gd.CURF{}:
      {==}
    case Gd.CUFL{}:
      {==}
    case Gd.CULB{}:
      {==}
    case Gd.CUBR{}:
      {==}
    case Gd.CDFR{}:
      {==}
    case Gd.CDLF{}:
      {==}
    case Gd.CDBL{}:
      {==}
    case Gd.CDRB{}:
      {==}

def Laws.refuse_flipped(e):
  match e:
    case Gd.EUR{}:
      {==}
    case Gd.EUF{}:
      {==}
    case Gd.EUL{}:
      {==}
    case Gd.EUB{}:
      {==}
    case Gd.EDR{}:
      {==}
    case Gd.EDF{}:
      {==}
    case Gd.EDL{}:
      {==}
    case Gd.EDB{}:
      {==}
    case Gd.EFR{}:
      {==}
    case Gd.EFL{}:
      {==}
    case Gd.EBL{}:
      {==}
    case Gd.EBR{}:
      {==}

def Laws.refuse_edges_swapped(e):
  match e:
    case Gd.EUR{}:
      {==}
    case Gd.EUF{}:
      {==}
    case Gd.EUL{}:
      {==}
    case Gd.EUB{}:
      {==}
    case Gd.EDR{}:
      {==}
    case Gd.EDF{}:
      {==}
    case Gd.EDL{}:
      {==}
    case Gd.EDB{}:
      {==}
    case Gd.EFR{}:
      {==}
    case Gd.EFL{}:
      {==}
    case Gd.EBL{}:
      {==}
    case Gd.EBR{}:
      {==}

def Laws.refuse_painted(f):
  match f:
    case G.FU{}:
      {==}
    case G.FR{}:
      {==}
    case G.FF{}:
      {==}
    case G.FD{}:
      {==}
    case G.FL{}:
      {==}
    case G.FB{}:
      {==}

def Laws.fst_step():
  {==}

def Laws.fst_rank_0():
  {==}

def Laws.fst_rank_1():
  {==}

def Laws.fst_rank_2():
  {==}

def Laws.fst_rank_3():
  {==}

def Laws.fst_rank_4():
  {==}

def Laws.fst_rank_5():
  {==}

def Laws.fst_rank_6():
  {==}

def Laws.fst_rank_7():
  {==}

def Laws.fst_rank_8():
  {==}

def Laws.fst_rank_9():
  {==}

def Laws.fst_rank_10():
  {==}

def Laws.fst_rank_11():
  {==}

def Laws.fst_rank_12():
  {==}

def Laws.fst_rank_13():
  {==}

def Laws.fst_rank_14():
  {==}

def Laws.fst_rank_15():
  {==}

def Laws.fst_home_mask():
  {==}

def Laws.fst_home():
  {==}
