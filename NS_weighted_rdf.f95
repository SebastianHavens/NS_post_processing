program weighted_rdf

 implicit none

 integer, parameter :: dp = kind(0.0q0)
 real(dp), allocatable, dimension(:)    :: temperature, beta, bin, rdf, Z
 real(dp), allocatable, dimension(:,:)  :: SUM_rdf

 character(len=60) :: arg0
 character(len=60),allocatable, dimension(:) ::  arg1, arg2
 character(len=60) :: rdf_filename, ener_filename
 real(dp) :: w, boltzmann_this, ener, delta_temp, start_temp, max_rdf, k_B

 integer :: i, j, k, N_point, N_rdf, N_bin_rdf, N_temp, iter, iter_p, ierr, io, n_file, i_file

 read(*,*) rdf_filename, ener_filename, N_point, N_bin_rdf, start_temp, N_temp, delta_temp, k_B

 allocate ( temperature(N_temp), beta(N_temp), Z(N_temp), STAT=ierr)
 Z=0.0_dp

 ! initialise the temperatures and beta
 temperature(1) = start_temp
 do i = 2,N_temp
    temperature(i) = temperature(i-1) + delta_temp
 enddo
 beta = 1.0_dp / (k_B*temperature)

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