 program weighted_rdf

 implicit none

 integer, parameter :: dp = kind(0.0q0)
 real(dp), parameter :: BOLTZMANN_K = 8.617385e-5_dp ! in eV/K
 !real(dp), parameter :: BOLTZMANN_K = 1.0_dp ! LJ unit
 !real(dp), parameter :: BOLTZMANN_K = 6.3336374823584e-6_dp ! in Rydberg/K

 real(dp), allocatable, dimension(:)    :: temperature, beta, bin, rdf, Z
 real(dp), allocatable, dimension(:,:)  :: SUM_rdf 

 character(len=60) :: arg0
 character(len=60),allocatable, dimension(:) ::  arg1, arg2
 character(len=60) :: rdf_filename, ener_filename
 real(dp) :: w, boltzmann_this, ener, delta_temp, start_temp, max_rdf, k_B

 integer :: i, j, k, N_point, N_rdf, N_bin_rdf, N_temp, iter, iter_p, ierr, io, n_file, i_file
 
! if (iargc() /= 0 ) then
!    call getarg(1,arg0) 
!    read(arg0,*) n_file
!    write(*,*) n_file
!
!    allocate(rdf_filename(n_file), arg1(n_file))
!    allocate(ener_filename(n_file), arg2(n_file))
!
!    call getarg(2,arg1)
!    read(arg1,*) rdf_filename
!    call getarg(3,arg2)
!    read(arg2,*) ener_filename
! else
!    write(*,*) 'Usage: ./NS_weighted_rdf <rdf_filemanem> <ener_filename>'
!    write(*,*) '{and do not forget the ns_temp.dat file with the rest of the parameters}'
!    stop
! endif
 read(*,*) rdf_filename, ener_filename, N_point, N_bin_rdf, start_temp, N_temp, delta_temp, k_B
! write(*,*) rdf_filename, ener_filename, N_point, N_bin_rdf!, N_temp, start_temp, delta_temp, k_B
! STOP
! open(111, file = "nwr.dat")
! read(111,*) n_file
! allocate(rdf_filename(n_file), arg1(n_file))
! allocate(ener_filename(n_file), arg2(n_file))
! do i=1,n_file
!    read(111,*) rdf_filename(i)
! enddo
! do i=1,n_file
!    read(111,*) ener_filename(i)
! enddo

 !write(*,*) "START"
 !open(1, file = "w_rdf_param.temp")
 !read(1,*) N_point    ! number of live points
 !read(1,*) N_bin_rdf  ! number of bins within the rdf
 !read(1,*) N_temp     ! number of temperatures
 !read(1,*) start_temp ! starting temperature
 !read(1,*) delta_temp ! delta temperature
 !close(1)

 allocate ( temperature(N_temp), beta(N_temp), Z(N_temp), STAT=ierr)
 Z=0.0_dp

 ! initialise the temperatures and beta
 temperature(1) = start_temp
 do i = 2,N_temp
    temperature(i) = temperature(i-1) + delta_temp
 enddo
 beta = 1.0_dp / (BOLTZMANN_K*temperature)

 allocate (bin(N_bin_rdf), rdf(N_bin_rdf))

 allocate ( SUM_rdf(N_bin_rdf,N_temp)  )
 SUM_rdf = 0.0_dp

 write(*, *) "START", rdf_filename, Z(1)
 open(222, file = rdf_filename)
 open(333, file = ener_filename)
 do
     iter_p = iter
     read(333, *, iostat = io) iter, ener
     if (io /= 0) exit


     ener = ener + 380.0_dp ! if the lowest energy is too low, the Boltzmann factor cannot be represented, not even in quad precision
     !ener = ener+1202.0_dp ! if the lowest energy is too low, the Boltzmann factor cannot be represented, not even in quad precision
     ! so it has to be shifted to be closer to one, so in the temperature range we're most likely to be interested
     ! this can be calculated. This does not effect the final result

     do j = 1, N_bin_rdf
         read(222, *) bin(j), rdf(j)
     enddo
     read(222, *)
     read(222, *)

     w = exp(-((iter - 1)) / real(N_point, dp)) - exp(-iter / real(N_point, dp))
     ! w is the NS weight, it really should be (K/(K+1))^(i-1) - (K/(K+1))^i
     ! does this make any difference?

     do k = 1, N_temp
         boltzmann_this = exp(-beta(k) * ener)
         Z(k) = Z(k) + boltzmann_this * w
         do j = 1, N_bin_rdf
             SUM_rdf(j, k) = SUM_rdf(j, k) + rdf(j) * boltzmann_this * w
         enddo
     enddo

 enddo
 close(222)
 close(333)


 !SUM_rdf = SUM_rdf / real(N_rdf, kind = dp) 

 do i = 1,N_temp    
    SUM_rdf(:,i) = SUM_rdf(:,i)/Z(i)
    do j = 1,N_bin_rdf
       if (SUM_rdf(j,i) < 1.0e-30) SUM_rdf(j,i) = 0.0_dp ! get rid of numerical noise
       write(*,'(f8.3,x,f8.3,x,e29.10)') temperature(i), bin(j), SUM_rdf(j,i)
    enddo
    write(*,*)  
    write(*,*)  
 enddo

 END program

