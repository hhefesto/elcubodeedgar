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
import ./Photo.bend as Ph
import ./Scheme.bend as Sc
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

def Laws.photo_lines(a, b):
  match a b:
    case G.FU{} G.FU{}:
      {==}
    case G.FU{} G.FR{}:
      {==}
    case G.FU{} G.FF{}:
      {==}
    case G.FU{} G.FD{}:
      {==}
    case G.FU{} G.FL{}:
      {==}
    case G.FU{} G.FB{}:
      {==}
    case G.FR{} G.FU{}:
      {==}
    case G.FR{} G.FR{}:
      {==}
    case G.FR{} G.FF{}:
      {==}
    case G.FR{} G.FD{}:
      {==}
    case G.FR{} G.FL{}:
      {==}
    case G.FR{} G.FB{}:
      {==}
    case G.FF{} G.FU{}:
      {==}
    case G.FF{} G.FR{}:
      {==}
    case G.FF{} G.FF{}:
      {==}
    case G.FF{} G.FD{}:
      {==}
    case G.FF{} G.FL{}:
      {==}
    case G.FF{} G.FB{}:
      {==}
    case G.FD{} G.FU{}:
      {==}
    case G.FD{} G.FR{}:
      {==}
    case G.FD{} G.FF{}:
      {==}
    case G.FD{} G.FD{}:
      {==}
    case G.FD{} G.FL{}:
      {==}
    case G.FD{} G.FB{}:
      {==}
    case G.FL{} G.FU{}:
      {==}
    case G.FL{} G.FR{}:
      {==}
    case G.FL{} G.FF{}:
      {==}
    case G.FL{} G.FD{}:
      {==}
    case G.FL{} G.FL{}:
      {==}
    case G.FL{} G.FB{}:
      {==}
    case G.FB{} G.FU{}:
      {==}
    case G.FB{} G.FR{}:
      {==}
    case G.FB{} G.FF{}:
      {==}
    case G.FB{} G.FD{}:
      {==}
    case G.FB{} G.FL{}:
      {==}
    case G.FB{} G.FB{}:
      {==}

def Laws.photo_lines_empty():
  {==}

def Laws.photo_pose_front(f):
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

def Laws.photo_pose_top(f):
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

def Laws.photo_pose_corner(f):
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

def Laws.photo_same_face(a, b, l):
  match a b l:
    case G.FU{} G.FU{} Ph.Day{}:
      {==}
    case G.FU{} G.FU{} Ph.Lamp{}:
      {==}
    case G.FU{} G.FU{} Ph.Shade{}:
      {==}
    case G.FU{} G.FR{} Ph.Day{}:
      {==}
    case G.FU{} G.FR{} Ph.Lamp{}:
      {==}
    case G.FU{} G.FR{} Ph.Shade{}:
      {==}
    case G.FU{} G.FF{} Ph.Day{}:
      {==}
    case G.FU{} G.FF{} Ph.Lamp{}:
      {==}
    case G.FU{} G.FF{} Ph.Shade{}:
      {==}
    case G.FU{} G.FD{} Ph.Day{}:
      {==}
    case G.FU{} G.FD{} Ph.Lamp{}:
      {==}
    case G.FU{} G.FD{} Ph.Shade{}:
      {==}
    case G.FU{} G.FL{} Ph.Day{}:
      {==}
    case G.FU{} G.FL{} Ph.Lamp{}:
      {==}
    case G.FU{} G.FL{} Ph.Shade{}:
      {==}
    case G.FU{} G.FB{} Ph.Day{}:
      {==}
    case G.FU{} G.FB{} Ph.Lamp{}:
      {==}
    case G.FU{} G.FB{} Ph.Shade{}:
      {==}
    case G.FR{} G.FU{} Ph.Day{}:
      {==}
    case G.FR{} G.FU{} Ph.Lamp{}:
      {==}
    case G.FR{} G.FU{} Ph.Shade{}:
      {==}
    case G.FR{} G.FR{} Ph.Day{}:
      {==}
    case G.FR{} G.FR{} Ph.Lamp{}:
      {==}
    case G.FR{} G.FR{} Ph.Shade{}:
      {==}
    case G.FR{} G.FF{} Ph.Day{}:
      {==}
    case G.FR{} G.FF{} Ph.Lamp{}:
      {==}
    case G.FR{} G.FF{} Ph.Shade{}:
      {==}
    case G.FR{} G.FD{} Ph.Day{}:
      {==}
    case G.FR{} G.FD{} Ph.Lamp{}:
      {==}
    case G.FR{} G.FD{} Ph.Shade{}:
      {==}
    case G.FR{} G.FL{} Ph.Day{}:
      {==}
    case G.FR{} G.FL{} Ph.Lamp{}:
      {==}
    case G.FR{} G.FL{} Ph.Shade{}:
      {==}
    case G.FR{} G.FB{} Ph.Day{}:
      {==}
    case G.FR{} G.FB{} Ph.Lamp{}:
      {==}
    case G.FR{} G.FB{} Ph.Shade{}:
      {==}
    case G.FF{} G.FU{} Ph.Day{}:
      {==}
    case G.FF{} G.FU{} Ph.Lamp{}:
      {==}
    case G.FF{} G.FU{} Ph.Shade{}:
      {==}
    case G.FF{} G.FR{} Ph.Day{}:
      {==}
    case G.FF{} G.FR{} Ph.Lamp{}:
      {==}
    case G.FF{} G.FR{} Ph.Shade{}:
      {==}
    case G.FF{} G.FF{} Ph.Day{}:
      {==}
    case G.FF{} G.FF{} Ph.Lamp{}:
      {==}
    case G.FF{} G.FF{} Ph.Shade{}:
      {==}
    case G.FF{} G.FD{} Ph.Day{}:
      {==}
    case G.FF{} G.FD{} Ph.Lamp{}:
      {==}
    case G.FF{} G.FD{} Ph.Shade{}:
      {==}
    case G.FF{} G.FL{} Ph.Day{}:
      {==}
    case G.FF{} G.FL{} Ph.Lamp{}:
      {==}
    case G.FF{} G.FL{} Ph.Shade{}:
      {==}
    case G.FF{} G.FB{} Ph.Day{}:
      {==}
    case G.FF{} G.FB{} Ph.Lamp{}:
      {==}
    case G.FF{} G.FB{} Ph.Shade{}:
      {==}
    case G.FD{} G.FU{} Ph.Day{}:
      {==}
    case G.FD{} G.FU{} Ph.Lamp{}:
      {==}
    case G.FD{} G.FU{} Ph.Shade{}:
      {==}
    case G.FD{} G.FR{} Ph.Day{}:
      {==}
    case G.FD{} G.FR{} Ph.Lamp{}:
      {==}
    case G.FD{} G.FR{} Ph.Shade{}:
      {==}
    case G.FD{} G.FF{} Ph.Day{}:
      {==}
    case G.FD{} G.FF{} Ph.Lamp{}:
      {==}
    case G.FD{} G.FF{} Ph.Shade{}:
      {==}
    case G.FD{} G.FD{} Ph.Day{}:
      {==}
    case G.FD{} G.FD{} Ph.Lamp{}:
      {==}
    case G.FD{} G.FD{} Ph.Shade{}:
      {==}
    case G.FD{} G.FL{} Ph.Day{}:
      {==}
    case G.FD{} G.FL{} Ph.Lamp{}:
      {==}
    case G.FD{} G.FL{} Ph.Shade{}:
      {==}
    case G.FD{} G.FB{} Ph.Day{}:
      {==}
    case G.FD{} G.FB{} Ph.Lamp{}:
      {==}
    case G.FD{} G.FB{} Ph.Shade{}:
      {==}
    case G.FL{} G.FU{} Ph.Day{}:
      {==}
    case G.FL{} G.FU{} Ph.Lamp{}:
      {==}
    case G.FL{} G.FU{} Ph.Shade{}:
      {==}
    case G.FL{} G.FR{} Ph.Day{}:
      {==}
    case G.FL{} G.FR{} Ph.Lamp{}:
      {==}
    case G.FL{} G.FR{} Ph.Shade{}:
      {==}
    case G.FL{} G.FF{} Ph.Day{}:
      {==}
    case G.FL{} G.FF{} Ph.Lamp{}:
      {==}
    case G.FL{} G.FF{} Ph.Shade{}:
      {==}
    case G.FL{} G.FD{} Ph.Day{}:
      {==}
    case G.FL{} G.FD{} Ph.Lamp{}:
      {==}
    case G.FL{} G.FD{} Ph.Shade{}:
      {==}
    case G.FL{} G.FL{} Ph.Day{}:
      {==}
    case G.FL{} G.FL{} Ph.Lamp{}:
      {==}
    case G.FL{} G.FL{} Ph.Shade{}:
      {==}
    case G.FL{} G.FB{} Ph.Day{}:
      {==}
    case G.FL{} G.FB{} Ph.Lamp{}:
      {==}
    case G.FL{} G.FB{} Ph.Shade{}:
      {==}
    case G.FB{} G.FU{} Ph.Day{}:
      {==}
    case G.FB{} G.FU{} Ph.Lamp{}:
      {==}
    case G.FB{} G.FU{} Ph.Shade{}:
      {==}
    case G.FB{} G.FR{} Ph.Day{}:
      {==}
    case G.FB{} G.FR{} Ph.Lamp{}:
      {==}
    case G.FB{} G.FR{} Ph.Shade{}:
      {==}
    case G.FB{} G.FF{} Ph.Day{}:
      {==}
    case G.FB{} G.FF{} Ph.Lamp{}:
      {==}
    case G.FB{} G.FF{} Ph.Shade{}:
      {==}
    case G.FB{} G.FD{} Ph.Day{}:
      {==}
    case G.FB{} G.FD{} Ph.Lamp{}:
      {==}
    case G.FB{} G.FD{} Ph.Shade{}:
      {==}
    case G.FB{} G.FL{} Ph.Day{}:
      {==}
    case G.FB{} G.FL{} Ph.Lamp{}:
      {==}
    case G.FB{} G.FL{} Ph.Shade{}:
      {==}
    case G.FB{} G.FB{} Ph.Day{}:
      {==}
    case G.FB{} G.FB{} Ph.Lamp{}:
      {==}
    case G.FB{} G.FB{} Ph.Shade{}:
      {==}

def Laws.scheme_six(p):
  match p:
    case Sc.Standard{}:
      {==}
    case Sc.Stickerless{}:
      {==}
    case Sc.Japanese{}:
      {==}
    case Sc.Mirrored{}:
      {==}
    case Sc.Pastel{}:
      {==}

def Laws.scheme_key(p):
  match p:
    case Sc.Standard{}:
      {==}
    case Sc.Stickerless{}:
      {==}
    case Sc.Japanese{}:
      {==}
    case Sc.Mirrored{}:
      {==}
    case Sc.Pastel{}:
      {==}

def Laws.scheme_own():
  {==}

def Laws.scheme_japanese():
  {==}

def Laws.scheme_mirrored():
  {==}

def Laws.scheme_say_standard(a, b):
  match a b:
    case G.FU{} G.FU{}:
      {==}
    case G.FU{} G.FR{}:
      {==}
    case G.FU{} G.FF{}:
      {==}
    case G.FU{} G.FD{}:
      {==}
    case G.FU{} G.FL{}:
      {==}
    case G.FU{} G.FB{}:
      {==}
    case G.FR{} G.FU{}:
      {==}
    case G.FR{} G.FR{}:
      {==}
    case G.FR{} G.FF{}:
      {==}
    case G.FR{} G.FD{}:
      {==}
    case G.FR{} G.FL{}:
      {==}
    case G.FR{} G.FB{}:
      {==}
    case G.FF{} G.FU{}:
      {==}
    case G.FF{} G.FR{}:
      {==}
    case G.FF{} G.FF{}:
      {==}
    case G.FF{} G.FD{}:
      {==}
    case G.FF{} G.FL{}:
      {==}
    case G.FF{} G.FB{}:
      {==}
    case G.FD{} G.FU{}:
      {==}
    case G.FD{} G.FR{}:
      {==}
    case G.FD{} G.FF{}:
      {==}
    case G.FD{} G.FD{}:
      {==}
    case G.FD{} G.FL{}:
      {==}
    case G.FD{} G.FB{}:
      {==}
    case G.FL{} G.FU{}:
      {==}
    case G.FL{} G.FR{}:
      {==}
    case G.FL{} G.FF{}:
      {==}
    case G.FL{} G.FD{}:
      {==}
    case G.FL{} G.FL{}:
      {==}
    case G.FL{} G.FB{}:
      {==}
    case G.FB{} G.FU{}:
      {==}
    case G.FB{} G.FR{}:
      {==}
    case G.FB{} G.FF{}:
      {==}
    case G.FB{} G.FD{}:
      {==}
    case G.FB{} G.FL{}:
      {==}
    case G.FB{} G.FB{}:
      {==}

def Laws.scheme_say_face(p, f):
  match p f:
    case Sc.Standard{} G.FU{}:
      {==}
    case Sc.Standard{} G.FR{}:
      {==}
    case Sc.Standard{} G.FF{}:
      {==}
    case Sc.Standard{} G.FD{}:
      {==}
    case Sc.Standard{} G.FL{}:
      {==}
    case Sc.Standard{} G.FB{}:
      {==}
    case Sc.Stickerless{} G.FU{}:
      {==}
    case Sc.Stickerless{} G.FR{}:
      {==}
    case Sc.Stickerless{} G.FF{}:
      {==}
    case Sc.Stickerless{} G.FD{}:
      {==}
    case Sc.Stickerless{} G.FL{}:
      {==}
    case Sc.Stickerless{} G.FB{}:
      {==}
    case Sc.Japanese{} G.FU{}:
      {==}
    case Sc.Japanese{} G.FR{}:
      {==}
    case Sc.Japanese{} G.FF{}:
      {==}
    case Sc.Japanese{} G.FD{}:
      {==}
    case Sc.Japanese{} G.FL{}:
      {==}
    case Sc.Japanese{} G.FB{}:
      {==}
    case Sc.Mirrored{} G.FU{}:
      {==}
    case Sc.Mirrored{} G.FR{}:
      {==}
    case Sc.Mirrored{} G.FF{}:
      {==}
    case Sc.Mirrored{} G.FD{}:
      {==}
    case Sc.Mirrored{} G.FL{}:
      {==}
    case Sc.Mirrored{} G.FB{}:
      {==}
    case Sc.Pastel{} G.FU{}:
      {==}
    case Sc.Pastel{} G.FR{}:
      {==}
    case Sc.Pastel{} G.FF{}:
      {==}
    case Sc.Pastel{} G.FD{}:
      {==}
    case Sc.Pastel{} G.FL{}:
      {==}
    case Sc.Pastel{} G.FB{}:
      {==}

def Laws.scheme_pick_six(p, f, g):
  match p f g:
    case Sc.Standard{} G.FU{} G.FU{}:
      {==}
    case Sc.Standard{} G.FU{} G.FR{}:
      {==}
    case Sc.Standard{} G.FU{} G.FF{}:
      {==}
    case Sc.Standard{} G.FU{} G.FD{}:
      {==}
    case Sc.Standard{} G.FU{} G.FL{}:
      {==}
    case Sc.Standard{} G.FU{} G.FB{}:
      {==}
    case Sc.Standard{} G.FR{} G.FU{}:
      {==}
    case Sc.Standard{} G.FR{} G.FR{}:
      {==}
    case Sc.Standard{} G.FR{} G.FF{}:
      {==}
    case Sc.Standard{} G.FR{} G.FD{}:
      {==}
    case Sc.Standard{} G.FR{} G.FL{}:
      {==}
    case Sc.Standard{} G.FR{} G.FB{}:
      {==}
    case Sc.Standard{} G.FF{} G.FU{}:
      {==}
    case Sc.Standard{} G.FF{} G.FR{}:
      {==}
    case Sc.Standard{} G.FF{} G.FF{}:
      {==}
    case Sc.Standard{} G.FF{} G.FD{}:
      {==}
    case Sc.Standard{} G.FF{} G.FL{}:
      {==}
    case Sc.Standard{} G.FF{} G.FB{}:
      {==}
    case Sc.Standard{} G.FD{} G.FU{}:
      {==}
    case Sc.Standard{} G.FD{} G.FR{}:
      {==}
    case Sc.Standard{} G.FD{} G.FF{}:
      {==}
    case Sc.Standard{} G.FD{} G.FD{}:
      {==}
    case Sc.Standard{} G.FD{} G.FL{}:
      {==}
    case Sc.Standard{} G.FD{} G.FB{}:
      {==}
    case Sc.Standard{} G.FL{} G.FU{}:
      {==}
    case Sc.Standard{} G.FL{} G.FR{}:
      {==}
    case Sc.Standard{} G.FL{} G.FF{}:
      {==}
    case Sc.Standard{} G.FL{} G.FD{}:
      {==}
    case Sc.Standard{} G.FL{} G.FL{}:
      {==}
    case Sc.Standard{} G.FL{} G.FB{}:
      {==}
    case Sc.Standard{} G.FB{} G.FU{}:
      {==}
    case Sc.Standard{} G.FB{} G.FR{}:
      {==}
    case Sc.Standard{} G.FB{} G.FF{}:
      {==}
    case Sc.Standard{} G.FB{} G.FD{}:
      {==}
    case Sc.Standard{} G.FB{} G.FL{}:
      {==}
    case Sc.Standard{} G.FB{} G.FB{}:
      {==}
    case Sc.Stickerless{} G.FU{} G.FU{}:
      {==}
    case Sc.Stickerless{} G.FU{} G.FR{}:
      {==}
    case Sc.Stickerless{} G.FU{} G.FF{}:
      {==}
    case Sc.Stickerless{} G.FU{} G.FD{}:
      {==}
    case Sc.Stickerless{} G.FU{} G.FL{}:
      {==}
    case Sc.Stickerless{} G.FU{} G.FB{}:
      {==}
    case Sc.Stickerless{} G.FR{} G.FU{}:
      {==}
    case Sc.Stickerless{} G.FR{} G.FR{}:
      {==}
    case Sc.Stickerless{} G.FR{} G.FF{}:
      {==}
    case Sc.Stickerless{} G.FR{} G.FD{}:
      {==}
    case Sc.Stickerless{} G.FR{} G.FL{}:
      {==}
    case Sc.Stickerless{} G.FR{} G.FB{}:
      {==}
    case Sc.Stickerless{} G.FF{} G.FU{}:
      {==}
    case Sc.Stickerless{} G.FF{} G.FR{}:
      {==}
    case Sc.Stickerless{} G.FF{} G.FF{}:
      {==}
    case Sc.Stickerless{} G.FF{} G.FD{}:
      {==}
    case Sc.Stickerless{} G.FF{} G.FL{}:
      {==}
    case Sc.Stickerless{} G.FF{} G.FB{}:
      {==}
    case Sc.Stickerless{} G.FD{} G.FU{}:
      {==}
    case Sc.Stickerless{} G.FD{} G.FR{}:
      {==}
    case Sc.Stickerless{} G.FD{} G.FF{}:
      {==}
    case Sc.Stickerless{} G.FD{} G.FD{}:
      {==}
    case Sc.Stickerless{} G.FD{} G.FL{}:
      {==}
    case Sc.Stickerless{} G.FD{} G.FB{}:
      {==}
    case Sc.Stickerless{} G.FL{} G.FU{}:
      {==}
    case Sc.Stickerless{} G.FL{} G.FR{}:
      {==}
    case Sc.Stickerless{} G.FL{} G.FF{}:
      {==}
    case Sc.Stickerless{} G.FL{} G.FD{}:
      {==}
    case Sc.Stickerless{} G.FL{} G.FL{}:
      {==}
    case Sc.Stickerless{} G.FL{} G.FB{}:
      {==}
    case Sc.Stickerless{} G.FB{} G.FU{}:
      {==}
    case Sc.Stickerless{} G.FB{} G.FR{}:
      {==}
    case Sc.Stickerless{} G.FB{} G.FF{}:
      {==}
    case Sc.Stickerless{} G.FB{} G.FD{}:
      {==}
    case Sc.Stickerless{} G.FB{} G.FL{}:
      {==}
    case Sc.Stickerless{} G.FB{} G.FB{}:
      {==}
    case Sc.Japanese{} G.FU{} G.FU{}:
      {==}
    case Sc.Japanese{} G.FU{} G.FR{}:
      {==}
    case Sc.Japanese{} G.FU{} G.FF{}:
      {==}
    case Sc.Japanese{} G.FU{} G.FD{}:
      {==}
    case Sc.Japanese{} G.FU{} G.FL{}:
      {==}
    case Sc.Japanese{} G.FU{} G.FB{}:
      {==}
    case Sc.Japanese{} G.FR{} G.FU{}:
      {==}
    case Sc.Japanese{} G.FR{} G.FR{}:
      {==}
    case Sc.Japanese{} G.FR{} G.FF{}:
      {==}
    case Sc.Japanese{} G.FR{} G.FD{}:
      {==}
    case Sc.Japanese{} G.FR{} G.FL{}:
      {==}
    case Sc.Japanese{} G.FR{} G.FB{}:
      {==}
    case Sc.Japanese{} G.FF{} G.FU{}:
      {==}
    case Sc.Japanese{} G.FF{} G.FR{}:
      {==}
    case Sc.Japanese{} G.FF{} G.FF{}:
      {==}
    case Sc.Japanese{} G.FF{} G.FD{}:
      {==}
    case Sc.Japanese{} G.FF{} G.FL{}:
      {==}
    case Sc.Japanese{} G.FF{} G.FB{}:
      {==}
    case Sc.Japanese{} G.FD{} G.FU{}:
      {==}
    case Sc.Japanese{} G.FD{} G.FR{}:
      {==}
    case Sc.Japanese{} G.FD{} G.FF{}:
      {==}
    case Sc.Japanese{} G.FD{} G.FD{}:
      {==}
    case Sc.Japanese{} G.FD{} G.FL{}:
      {==}
    case Sc.Japanese{} G.FD{} G.FB{}:
      {==}
    case Sc.Japanese{} G.FL{} G.FU{}:
      {==}
    case Sc.Japanese{} G.FL{} G.FR{}:
      {==}
    case Sc.Japanese{} G.FL{} G.FF{}:
      {==}
    case Sc.Japanese{} G.FL{} G.FD{}:
      {==}
    case Sc.Japanese{} G.FL{} G.FL{}:
      {==}
    case Sc.Japanese{} G.FL{} G.FB{}:
      {==}
    case Sc.Japanese{} G.FB{} G.FU{}:
      {==}
    case Sc.Japanese{} G.FB{} G.FR{}:
      {==}
    case Sc.Japanese{} G.FB{} G.FF{}:
      {==}
    case Sc.Japanese{} G.FB{} G.FD{}:
      {==}
    case Sc.Japanese{} G.FB{} G.FL{}:
      {==}
    case Sc.Japanese{} G.FB{} G.FB{}:
      {==}
    case Sc.Mirrored{} G.FU{} G.FU{}:
      {==}
    case Sc.Mirrored{} G.FU{} G.FR{}:
      {==}
    case Sc.Mirrored{} G.FU{} G.FF{}:
      {==}
    case Sc.Mirrored{} G.FU{} G.FD{}:
      {==}
    case Sc.Mirrored{} G.FU{} G.FL{}:
      {==}
    case Sc.Mirrored{} G.FU{} G.FB{}:
      {==}
    case Sc.Mirrored{} G.FR{} G.FU{}:
      {==}
    case Sc.Mirrored{} G.FR{} G.FR{}:
      {==}
    case Sc.Mirrored{} G.FR{} G.FF{}:
      {==}
    case Sc.Mirrored{} G.FR{} G.FD{}:
      {==}
    case Sc.Mirrored{} G.FR{} G.FL{}:
      {==}
    case Sc.Mirrored{} G.FR{} G.FB{}:
      {==}
    case Sc.Mirrored{} G.FF{} G.FU{}:
      {==}
    case Sc.Mirrored{} G.FF{} G.FR{}:
      {==}
    case Sc.Mirrored{} G.FF{} G.FF{}:
      {==}
    case Sc.Mirrored{} G.FF{} G.FD{}:
      {==}
    case Sc.Mirrored{} G.FF{} G.FL{}:
      {==}
    case Sc.Mirrored{} G.FF{} G.FB{}:
      {==}
    case Sc.Mirrored{} G.FD{} G.FU{}:
      {==}
    case Sc.Mirrored{} G.FD{} G.FR{}:
      {==}
    case Sc.Mirrored{} G.FD{} G.FF{}:
      {==}
    case Sc.Mirrored{} G.FD{} G.FD{}:
      {==}
    case Sc.Mirrored{} G.FD{} G.FL{}:
      {==}
    case Sc.Mirrored{} G.FD{} G.FB{}:
      {==}
    case Sc.Mirrored{} G.FL{} G.FU{}:
      {==}
    case Sc.Mirrored{} G.FL{} G.FR{}:
      {==}
    case Sc.Mirrored{} G.FL{} G.FF{}:
      {==}
    case Sc.Mirrored{} G.FL{} G.FD{}:
      {==}
    case Sc.Mirrored{} G.FL{} G.FL{}:
      {==}
    case Sc.Mirrored{} G.FL{} G.FB{}:
      {==}
    case Sc.Mirrored{} G.FB{} G.FU{}:
      {==}
    case Sc.Mirrored{} G.FB{} G.FR{}:
      {==}
    case Sc.Mirrored{} G.FB{} G.FF{}:
      {==}
    case Sc.Mirrored{} G.FB{} G.FD{}:
      {==}
    case Sc.Mirrored{} G.FB{} G.FL{}:
      {==}
    case Sc.Mirrored{} G.FB{} G.FB{}:
      {==}
    case Sc.Pastel{} G.FU{} G.FU{}:
      {==}
    case Sc.Pastel{} G.FU{} G.FR{}:
      {==}
    case Sc.Pastel{} G.FU{} G.FF{}:
      {==}
    case Sc.Pastel{} G.FU{} G.FD{}:
      {==}
    case Sc.Pastel{} G.FU{} G.FL{}:
      {==}
    case Sc.Pastel{} G.FU{} G.FB{}:
      {==}
    case Sc.Pastel{} G.FR{} G.FU{}:
      {==}
    case Sc.Pastel{} G.FR{} G.FR{}:
      {==}
    case Sc.Pastel{} G.FR{} G.FF{}:
      {==}
    case Sc.Pastel{} G.FR{} G.FD{}:
      {==}
    case Sc.Pastel{} G.FR{} G.FL{}:
      {==}
    case Sc.Pastel{} G.FR{} G.FB{}:
      {==}
    case Sc.Pastel{} G.FF{} G.FU{}:
      {==}
    case Sc.Pastel{} G.FF{} G.FR{}:
      {==}
    case Sc.Pastel{} G.FF{} G.FF{}:
      {==}
    case Sc.Pastel{} G.FF{} G.FD{}:
      {==}
    case Sc.Pastel{} G.FF{} G.FL{}:
      {==}
    case Sc.Pastel{} G.FF{} G.FB{}:
      {==}
    case Sc.Pastel{} G.FD{} G.FU{}:
      {==}
    case Sc.Pastel{} G.FD{} G.FR{}:
      {==}
    case Sc.Pastel{} G.FD{} G.FF{}:
      {==}
    case Sc.Pastel{} G.FD{} G.FD{}:
      {==}
    case Sc.Pastel{} G.FD{} G.FL{}:
      {==}
    case Sc.Pastel{} G.FD{} G.FB{}:
      {==}
    case Sc.Pastel{} G.FL{} G.FU{}:
      {==}
    case Sc.Pastel{} G.FL{} G.FR{}:
      {==}
    case Sc.Pastel{} G.FL{} G.FF{}:
      {==}
    case Sc.Pastel{} G.FL{} G.FD{}:
      {==}
    case Sc.Pastel{} G.FL{} G.FL{}:
      {==}
    case Sc.Pastel{} G.FL{} G.FB{}:
      {==}
    case Sc.Pastel{} G.FB{} G.FU{}:
      {==}
    case Sc.Pastel{} G.FB{} G.FR{}:
      {==}
    case Sc.Pastel{} G.FB{} G.FF{}:
      {==}
    case Sc.Pastel{} G.FB{} G.FD{}:
      {==}
    case Sc.Pastel{} G.FB{} G.FL{}:
      {==}
    case Sc.Pastel{} G.FB{} G.FB{}:
      {==}

def Laws.scheme_pick_presets():
  {==}
