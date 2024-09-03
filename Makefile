PROJ = lpcblaster
IMAGES = sblaster
SOURCES = sblaster.v ymf262.v ym_lib.v
PIN_DEF =  lpcblaster.pcf
DEVICE = hx8k
ODIR = build
DEPS = $(addprefix $(ODIR)/,$(addsuffix .d,$(IMAGES)))

# Want to build report and main bin file
all: $(addprefix $(ODIR)/,$(addsuffix .rpt,$(IMAGES))) $(ODIR)/$(PROJ).binm

# removed %.v
$(ODIR)/%.json: $(SOURCES)
	yosys -p 'synth_ice40 -top $(basename $(notdir $@)) -json $@' $(SOURCES) -E $(basename $(notdir $@)).d
#	yosys -p 'synth_ice40 -top mda_top -json $@' $(SOURCES) -E $(DEPS)
#	@echo yosys -p 'synth_ice40 -top isavideo -json $@' $^ -E $(DEPS)
	echo $@

$(ODIR)/%.asc: $(ODIR)/%.json $(PIN_DEF)
# add -q to quiet lots of messages
	nextpnr-ice40 -q --$(DEVICE) --pcf $(PIN_DEF) --json $< --asc $@ --package tq144:4k
#	@echo nextpnr $< $@

$(ODIR)/%.bin: $(ODIR)/%.asc
	icepack $< $@
#	@echo icepack $< $@

# Combined multiboot image
$(ODIR)/%.binm: $(addprefix $(ODIR)/,$(addsuffix .bin, $(IMAGES)))
	icemulti -c -o $@ $^

$(ODIR)/%.rpt: $(ODIR)/%.asc
	icetime -d $(DEVICE) -mtr $@ $<
#	@echo icetime -d $(DEVICE) -mtr $@ $<

sim: $(ODIR)/$(PROJ)_t.vcd

$(ODIR)/$(PROJ)_t.vcd: $(PROJ)_t.v $(SOURCES) is61c5128_t.v

prog: $(ODIR)/$(PROJ).binm
#	iCEburn  -e -v -w  $<
	iceprog -p $<

sudo-prog: $(ODIR)/$(PROJ).bin
	@echo 'Executing prog as root!!!'
	iCEburn  -e -v -w  $<

clean:
	rm -f $(ODIR)/$(PROJ).blif $(ODIR)/$(PROJ).asc $(ODIR)/$(PROJ).bin $(ODIR)/$(PROJ).json $(ODIR)/$(PROJ).d $(ODIR)/*.bin $(ODIR)/*.binm $(ODIR)/*.rpt

reset:
	iceprog -t

%.vcd:
	iverilog $^ -o $(@:.vcd=.out)
	vvp $(@:.vcd=.out)

# Don't delete individual images
PRECIOUS: $(addsuffix .bin, $(addprefix $(ODIR)/,$(IMAGES)))

.PHONY: all prog clean reset

# Depsfile
-include $(DEPS)
