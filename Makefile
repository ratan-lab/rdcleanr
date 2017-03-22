install:
	mkdir bin
	cp src/compute_gc_bias src/correct_gc_bias src/utils.py bin/
	cp src/VERSION bin/

.PHONY : clean

clean:
	rm -rf bin
