##
## Sumpis Project Maintenance Functions
##

# Location of perltidy
PERLTIDY = /home/orca/Perl-Tidy-20150815/perltidy

SRC = sumpis.pl dataTasks.pm castCals.pm  PrintFormat.pm \
      stats.pm castTasks.pm discreteSamples.pm processPH.pl \
      sumpis.pl fileParser.pm Seabird/HexCnv.pm

default:
	@echo "Use: 'make tidy' to run perltidy on the code"
	@echo "Use: 'make test' to run some sanity checks"
	@echo "Use: 'make clean' to remove detritus"

## make tidy :  reformat the source using my conventions
tidy:
	for X in $(SRC) ; do \
	    ${PERLTIDY} -bl -ce -b -i 2 -ci 4 -lp -pt 0 -sbt 0 $$X; \
	    perl -i -pe 's/^\s+$$/\n/g' $$X ; \
	done


test:	
	cd unitTesting; ./unitTest.pl

## Assuming a changes is made affecting the output format/values
## and that change is desired, run this to update the unit
## test files.
update_test:	test
	@cp unitTesting/processed/unaligned/201601/*.DGC unitTesting/verified/unaligned/201601
	@cp unitTesting/processed/aligned/201601/*.DGC unitTesting/verified/aligned/201601

clean:
	@rm *.bak  || true
	@rm unitTesting/run_*.out  || true
