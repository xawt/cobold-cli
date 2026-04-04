COBC    = cobc
COBFLAGS = -x
SRC     = src/main.cob
OUT     = dist/cobold

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	mkdir -p dist
	$(COBC) $(COBFLAGS) -o $(OUT) $(SRC)

clean:
	rm -rf dist
