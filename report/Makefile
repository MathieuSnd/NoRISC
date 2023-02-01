
.PHONY: all output.odt everything.md

OUTLINE = \
	abstract.md \
	introduction.md \
	paf.md \
	B.md \
	conclusion.md \
	references.md



all: output.odt
	open output.odt

output.odt: everything.md
	pandoc -o output.odt everything.md


everything.md: $(OUTLINE)
	cat $(OUTLINE) > everything.md


clean:
	rm -f everything.md
	rm -f output.odt