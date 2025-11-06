AS=ca65
LD=ld65

BUILD=build
SRC=src

CONFIG=$(SRC)/nrom128.cfg
BOOT=$(BUILD)/boot.bin
NES=$(BUILD)/boot.nes

all: $(NES)

# - Append iNES header
# 	- iNES signature: NES + 0x1a
# 	- 2 x16 kB PRG ROM
# 	- 1 x16 kB CHR
# 	- 10 byte padding (ignore this metadata fornow)
# - Duplicate the 8 kiB PRG ROM
# 	- ROMS start at $FFFD, which is in the $C000 block
# 	- The $8000-$BFFF block is unused here, so we just duplicate it.
#     - (Duplication replicates an absence of the A14 address pin)
# - Pad the CHR ROM with zeros (for now)

# NOTE: This should probably be a script or a tool.
$(NES): $(BOOT)
	printf "\x4e\x45\x53\x1a" > $@
	printf "\x02" >> $@
	printf "\x01" >> $@
	printf "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> $@
	cat $(BOOT) >> $@
	cat $(BOOT) >> $@
	dd if=/dev/zero bs=8192 count=1 >> $@ 2>/dev/null

# Build the ROM chip data
$(BOOT): $(BUILD)/boot.o $(CONFIG) | $(BUILD)
	$(LD) -C $(CONFIG) -o $@ $<

# Compile the asm
$(BUILD)/boot.o: $(SRC)/boot.s | $(BUILD)
	$(AS) -t none -o $@ $<

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)
