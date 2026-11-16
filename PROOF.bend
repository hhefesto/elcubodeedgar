# The proofs of LAWS.bend. Every law here is about finitely many moves, and
# each is proven by computation: a case for each face (and turn), where both
# sides compute to the same cube, so {==} closes it. Nothing here is trusted:
# `bend PROOF.bend` checks every def.

import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Group.bend as G
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

def Laws.ru_order():
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

