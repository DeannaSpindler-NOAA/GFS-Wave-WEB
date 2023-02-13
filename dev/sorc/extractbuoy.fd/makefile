SHELL=/bin/sh

SRCS=	extractbuoy.f cfl.f
OBJS=   extractbuoy.o cfl.o

# Tunable parameters
#
#
FC =          ifort
LDFLAGS =     
LIBS =   $(W3NCO_LIB4) $(BUFR_LIB4)
###LIBS =   -L/nwprod/lib -lw3nco_4 -lbufr_4_64 	
###LIBS =   -L/nwprod/lib -lw3emc_8 -lw3nco_8 -lbufr_4_64
CMD =	    extractbuoy	
PROFLIB =	

#FFLAGS =          -qinitauto -qintsize=8 -qrealsize=8
FFLAGS =         -O3 -g -r8 -i8 -convert big_endian -assume byterecl

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build a.out.
#
all:		$(CMD)

$(CMD):		$(OBJS)
	$(FC) $(LDFLAGS) $(FFLAGS) -o $(@) $(OBJS) $(LIBS)

# Make the profiled version of the command and call it a.out.prof
#
$(CMD).prof:	$(OBJS)
	$(FC) $(LDFLAGS) $(FFLAGS) -o $(@) $(OBJS) $(PROFLIB) $(LIBS)

clean:
	-rm -f $(OBJS)

clobber:	clean
	-rm -f $(CMD) $(CMD).prof

void:	clobber
	-rm -f $(SRCS) makefile
