module qed_evolution
  use types; use consts_dp
  use dglap_objects; use qcd_coupling
  use assertions; use qcd
  use qed_coupling_module
  use qed_objects
  use warnings_and_errors
  use dglap_holders; use pdf_representation
  ! this is shared with the main QCD evolution
  use evolution_helper
  implicit none

  private

  public :: QEDQCDEvolvePDF
  
  type(qed_split_mat), save :: qed_sm_copy
  integer             :: ev_nqcdloop_qed
  type(qed_coupling), pointer :: ev_coupling_qed
  
contains

  subroutine QEDQCDEvolvePDF(dh, qed_sm, pdf, coupling_qcd, coupling_qed,&
       &                     Q_init, Q_end, nloop_qcd, nqcdloop_qed)
    type(dglap_holder),     intent(in), target :: dh
    type(qed_split_mat),    intent(in), target :: qed_sm
    type(running_coupling), intent(in), target :: coupling_qcd
    type(qed_coupling),     intent(in), target :: coupling_qed
    
    real(dp),               intent(inout)      :: pdf(0:,ncompmin:)
    real(dp),               intent(in)         :: Q_init, Q_end
    integer,                intent(in)         :: nloop_qcd
    integer,                intent(in)         :: nqcdloop_qed
    !------------------------------------------------------
    ! iqed indicates which momentum region of the QED coupling
    ! we are working in
    integer  :: iqed, iqed_init, iqed_end, nflav(3), direction
    integer  :: nf_old, nf_new
    real(dp) :: lcl_Q_init, lcl_Q_end
    type(dglap_holder)  :: dhcopy
    
    ! these copies are cheap, because they just copy pointers
    dhcopy = dh
    qed_sm_copy = qed_sm
    ev_coupling_qed => coupling_qed
    
    ! set up "global" constants in evolution_helper module
    ev_ash => coupling_qcd
    call ev_SetModuleConsts(coupling=coupling_qcd, muR_Q=one, &
         &                  nloop=nloop_qcd, untie_nf=.false.)
    if (ev_nloop > dhcopy%nloop) &
         &call wae_error('QEDQCDEvolvePDF: dh%nloop must be >= nloop')
    
    ! establish evolution direction
    if (Q_end >= Q_init) then
       direction = 1
    else
       direction = -1
    end if

    ! establish which flavour regions we are working in
    ! (assume QCD and QED couplings have the same masses)
    iqed_init = iQEDThresholdAtQ(coupling_qed, Q_init)
    iqed_end  = iQEDThresholdAtQ(coupling_qed, Q_end )

    nf_old = coupling_qed%nflav(2,iqed_init) + coupling_qed%nflav(3,iqed_init)
    do iqed = iqed_init, iqed_end, direction
       ! there is no evolution to be done when iqed=0 (below electron mass)
       if (iqed == 0) cycle
       ! make sure we don't get into trouble here...
       if (iqed  > coupling_qed%n_thresholds) call wae_error("QEDQCDEvolvePDF", "iqed too high")
       if (direction == 1) then
          lcl_Q_init = max(Q_init, coupling_qed%thresholds(iqed  ))
          lcl_Q_end  = min(Q_end,  coupling_qed%thresholds(iqed+1))
       else
          lcl_Q_init = min(Q_init, coupling_qed%thresholds(iqed+1))
          lcl_Q_end  = max(Q_end,  coupling_qed%thresholds(iqed  ))
       end if

       ! set up the number of flavours
       ! (/ nleptons, ndown, nup /)
       nflav = coupling_qed%nflav(:,iqed)
       nf_new = nflav(2) + nflav(3)
       !write(0,*) lcl_Q_init, lcl_Q_end, nf_new 
       call SetNfDglapHolder(dhcopy, nf_new, QuarkMassesAreMSbar(coupling_qcd))
       call QEDSplitMatSetNf(qed_sm_copy, nflav(1), nflav(2), nflav(3))

       ! if we have changed nf, include threshold term
       if (nf_new /= nf_old) then
          call ev_CrossMassThreshold(dhcopy,coupling_qcd,direction,pdf(:,:ncompmax))
       end if

       !!-- NOW PREPARE EVOLUTION
       ev_PLO  => dhcopy%P_LO
       if (ev_nloop >= 2) ev_PNLO => dhcopy%P_NLO
       if (ev_nloop >= 3) ev_PNNLO => dhcopy%P_NNLO
       ev_nqcdloop_qed = nqcdloop_qed
       
       call ev_evolveLocal(pdf, lcl_Q_init, lcl_Q_end, ev_conv_qed)
       
       nf_old = nf_new
    end do
  end subroutine QEDQCDEvolvePDF
  

  subroutine ev_conv_qed(u, pdf, dpdf)
    use convolution
    real(dp), intent(in)  :: u, pdf(0:,ncompmin:)
    real(dp), intent(out) :: dpdf(0:,ncompmin:)
    !--------------
    real(dp) :: alpha
    dpdf = zero

    ! get the QCD part of the evolution
    call ev_conv(u, pdf(:,:ncompmax), dpdf(:,:ncompmax))

    
    ! then get the QED and mixed QED-QCD parts, making use of the
    ! jacobian, as2pi and last_Q values made available in ev_conv
    alpha = Value(ev_coupling_qed, ev_conv_last_Q)

    dpdf = dpdf + (alpha/twopi * ev_conv_last_jacobian) * (qed_sm_copy%lo * pdf)

    if (ev_nqcdloop_qed >= 1) then
       dpdf = dpdf + (ev_conv_last_as2pi * alpha/twopi * ev_conv_last_jacobian) &
            &        * (qed_sm_copy%nlo * pdf)
    end if

  end subroutine ev_conv_qed
  
end module qed_evolution
