!======================================================================
! QED splitting function. NB y == gamma
!
! Beyond leading order, these are taken from arXiv:1512.00612
!
! Their notation (Eqs.6-7) is that
!
! - P_{q_i q_k} = \delta_{ik} P_{qq}^V + P_{qq}^S
!
! - P_{q_i \bar q_k} = \delta_{ik} P_{q \barq}^V + P_{q\bar q}^S
!
! - P^{\pm}_q = P_{qq}^V \pm P_{q\bar q}^V
!
module qed_splitting_functions
  use types; use consts_dp; use convolution_communicator
  use qcd; use warnings_and_errors
  use splitting_functions
  implicit none
  private

  public :: sf_Pqq_01, sf_Pqy_01, sf_Pyq_01, sf_Pyy_01
  public :: sf_Pqg_11, sf_Pyg_11, sf_Pgg_11
  public :: sf_PqqV_11, sf_PqqbarV_11, sf_Pgq_11
contains

  !----------------------------------------------------------------------
  ! this is to be multplied by the eq^2
  function sf_Pqq_01(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    res = sf_Pqq(y) / CF
  end function sf_Pqq_01

  !----------------------------------------------------------------------
  ! this is to be multplied by the eq^2 -- SHOULD THIS NOT HAVE AN
  ! EXTRA ACTOR OF NC = CA ?????
  function sf_Pqy_01(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    res = sf_Pqg(y) / TR
  end function sf_Pqy_01

  !----------------------------------------------------------------------
  ! this is to be multplied by the eq^2
  function sf_Pyq_01(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    res = sf_Pgq(y) / CF
  end function sf_Pyq_01

  !----------------------------------------------------------------------
  ! this is to be multiplied by ef^2 = NC \sum_q eq^2 + \sum_l el^2
  function sf_Pyy_01(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    real(dp)             :: x
    x = exp(-y)
    res = zero
    select case(cc_piece)
    case(cc_DELTA)
       res = - two/three
    end select
    if (cc_piece /= cc_DELTA) res = res * x
  end function sf_Pyy_01

  !======================================================================
  ! now the NLO ones

  !----------------------------------------------------------------------
  ! this is to be multiplied by eq^2
  function sf_Pqg_11(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    real(dp)             :: x, lnx, ln1mx, pqg
    x = exp(-y)
    lnx = -y
    ln1mx = log(one - x)
    res = zero

    select case(cc_piece)
    case(cc_REAL,cc_REALVIRT)
       pqg   = x**2 + (one-x)**2
       res = TR * half*(4 - 9*x - (1-4*x)*lnx - (1-2*x)*lnx**2 + 4*ln1mx&
             + pqg*(2*(ln1mx-lnx)**2 - 4*(ln1mx-lnx) - two*pisq/three + 10))
    end select
    select case(cc_piece)
    case(cc_VIRT,cc_REALVIRT)
    case(cc_DELTA)
    end select

    if (cc_piece /= cc_DELTA) res = res * x
  end function sf_Pqg_11
  

  !----------------------------------------------------------------------
  ! this is to be multiplied by \sum_j=1^nf eqj^2
  function sf_Pyg_11(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    real(dp)             :: x, lnx
    x = exp(-y)
    lnx = -y
    res = zero

    select case(cc_piece)
    case(cc_REAL,cc_REALVIRT)
       res = TR * (-16 + 8*x + 20*x**2/three + four/(3*x) &
            &      -(6+10*x)*lnx - 2*(1+x)*lnx**2)
    end select
    select case(cc_piece)
    case(cc_VIRT,cc_REALVIRT)
    case(cc_DELTA)
    end select

    if (cc_piece /= cc_DELTA) res = res * x
  end function sf_Pyg_11

  
  !----------------------------------------------------------------------
  ! this is to be multiplied by \sum_j=1^nf eqj^2
  function sf_Pgg_11(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    real(dp)             :: x
    x = exp(-y)
    res = zero
    select case(cc_piece)
    case(cc_DELTA)
       res = - TR
    end select
    if (cc_piece /= cc_DELTA) res = res * x
  end function sf_Pgg_11


  !----------------------------------------------------------------------
  ! to be multiplied by eq^2
  function sf_PqqV_11(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    real(dp)             :: x, lnx, ln1mx, pqq
    x = exp(-y)
    lnx = -y
    ln1mx = log(one - x)
    res = zero

    select case(cc_piece)
    case(cc_REAL,cc_REALVIRT)
       pqq = two/(one-x) - one - x
       res = -two*CF*(&
            &  (2*lnx*ln1mx + 1.5_dp*lnx)*pqq&
            &   + (three+7.0_dp*x)/two * lnx&
            &   + (one+x)/two * lnx**2&
            &   + 5*(one-x))
    end select
    select case(cc_piece)
    case(cc_VIRT,cc_REALVIRT)
    case(cc_DELTA)
       res = -two*CF*(pisq/two - three/8.0_dp - 6 * zeta3)
    end select

    if (cc_piece /= cc_DELTA) res = res * x
  end function sf_PqqV_11

  !----------------------------------------------------------------------
  ! to be multiplied by eq^2
  function sf_PqqbarV_11(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    real(dp)             :: x, lnx, ln1mx, pqqmx
    x = exp(-y)
    lnx = -y
    ln1mx = log(one - x)
    res = zero

    select case(cc_piece)
    case(cc_REAL,cc_REALVIRT)
       pqqmx = two/(one+x) - one + x
       res = two*CF*(&
            &   4*(1-x)&
            &  + 2*(1+x)*lnx&
            &  + 2*pqqmx * sf_S2(x))
    end select
    select case(cc_piece)
    case(cc_VIRT,cc_REALVIRT)
    case(cc_DELTA)
    end select

    if (cc_piece /= cc_DELTA) res = res * x
  end function sf_PqqbarV_11

  !----------------------------------------------------------------------
  ! to be multiplied by eq^2
  ! Pyq_11 is identical
  function sf_Pgq_11(y) result(res)
    real(dp), intent(in) :: y
    real(dp)             :: res
    real(dp)             :: x, lnx, ln1mx, pgq
    x = exp(-y)
    lnx = -y
    ln1mx = log(one - x)
    res = zero

    select case(cc_piece)
    case(cc_REAL,cc_REALVIRT)
       pgq = (one + (one-x)**2)/x
       res = CF*(&
            &  -(three*ln1mx + ln1mx**2)*pgq&
            &  + (two + 7.0_dp/two * x)*lnx&
            &  - (1-half*x)*lnx**2&
            &  - two*x*ln1mx&
            &  - 7.0_dp*x/two - 5.0_dp/two)
    end select
    select case(cc_piece)
    case(cc_VIRT,cc_REALVIRT)
    case(cc_DELTA)
    end select
    if (cc_piece /= cc_DELTA) res = res * x
  end function sf_Pgq_11
  

end module qed_splitting_functions
