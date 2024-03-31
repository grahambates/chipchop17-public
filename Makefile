name=chipchop17
program=out/a

# Emulator options
BUILD=hunk
DEBUG=0
MODEL=A500
FASTMEM=0
CHIPMEM=512
SLOWMEM=512

BIN_DIR = ~/amiga/bin

# Binaries
CC = m68k-amiga-elf-gcc
ELF2HUNK = elf2hunk
VASM = $(BIN_DIR)/vasmm68k_mot
VLINK = $(BIN_DIR)/vlink
KINGCON = $(BIN_DIR)/kingcon
AMIGECONV = $(BIN_DIR)/amigeconv
FSUAE = /Applications/FS-UAE-3.app/Contents/MacOS/fs-uae
VAMIGA = /Applications/vAmiga.app/Contents/MacOS/vAmiga
# LSPCONVERT = $(BIN_DIR)/LSPConvert
LSPCONVERT = wine $(BIN_DIR)/LSPConvert.exe
SALVADOR = $(BIN_DIR)/salvador
ZX0 = $(BIN_DIR)/zx0
ADFTRACK = tools/adftrack

# Flags:
VASMFLAGS = -m68000 -opt-fconst -nowarn=62 -x -DDEBUG=$(DEBUG)
VLINKFLAGS = -bamigahunk -Bstatic
CCFLAGS = -g -MP -MMD -m68000 -Ofast -nostdlib -Wextra -fomit-frame-pointer -fno-tree-loop-distribution -flto -fwhole-program
LDFLAGS = -Wl,--emit-relocs,-Ttext=0
FSUAEFLAGS = --automatic_input_grab=0  --chip_memory=$(CHIPMEM) --fast_memory=$(FASTMEM) --slow_memory=$(SLOWMEM) --amiga_model=$(MODEL) --console-debugger=1 --joystick_port_0=0 --joystick_port_1=0

exe = out/$(name).$(BUILD).exe
dist_exe = dist/$(name)
adf = dist/$(name).adf
sources := main.asm $(wildcard *.asm)
elf_objects := $(sources:.asm=.elf)
hunk_objects := $(sources:.asm=.hunk)
deps := $(sources:.asm=.d)

mods := $(wildcard mods/*mod)
modz := $(mods:.mod=.mod.zx0)

tracks =\
		mods/GH_Introduction.mod.zx0 \
		mods/Bay-Tremore_Old-Times.mod.zx0 \
		mods/Laamaa_Saint-Lager.mod.zx0 \
		mods/Tobikomi_Namkey.mod.zx0 \
		mods/Alpa-and-Ziphoid_As-We-Remain.mod.zx0 \
		mods/Curt-Cool_Bloated-Colonel.mod.zx0 \
		mods/Gemini_Dash.mod.zx0 \
		mods/Andy_Chypnotized.mod.zx0 \
		mods/Punnik_Lies.mod.zx0 \
		mods/Maak_Q-bix.mod.zx0 \
		mods/Virgill_Keygen-X.mod.zx0 \
		mods/Soda7_Appeal.mod.zx0 \
		mods/Turbo-Knight-Rapture_Longtime.mod.zx0 \
		mods/Notorious_Mitten-Smitten.mod.zx0 \
		mods/XYCE_Le-Courant.mod.zx0 \
		mods/Okeanos_The-Dawn-Skies.mod.zx0 \
		mods/Robyn_Purplelily.mod.zx0 \
		mods/Earthling_Two-Track-Wonder.mod.zx0 \
		mods/Tecon_Engage.mod.zx0 \
		mods/Neuroflip_Free-Carmela.mod.zx0 \
		mods/mA2E_Aurora-Nights.mod.zx0 \
		mods/Rapture_Space-Ratatouille.mod.zx0 \
		mods/Octapus_Astro-Swong.mod.zx0 \
		mods/Nooly_Good-Times-Are-Now.mod.zx0 \
		mods/Yzi_Ennenolichipitrautaa.mod.zx0 \
		mods/Dvibe_Halv-Tre-Kaffet.mod.zx0 \
		mods/ne7_Friday-Feelin.mod.zx0 \
		mods/Triace_Uplifter.mod.zx0 \
		mods/Uctumi_Disqualified.mod.zx0 \
		mods/Ulrick_Machineras.mod.zx0 \
		mods/No-XS_At-Choic3.mod.zx0 \
		mods/Josss_Moonshiner!.mod.zx0 \
		mods/Hyperunknow_Goat-Fiction.mod.zx0 \
		mods/Alex-Menchi_Welcome-to-the-party.mod.zx0 \
		mods/Gouafhg_Brenda-and-Dylan.mod.zx0 \
		mods/TFX_Willows.mod.zx0 \
		mods/Dusthillresident_Tetsujin.mod.zx0 \
		mods/Slash_Filling-it-Up.mod.zx0 \
		mods/Buddy_105-Fahrenheit.mod.zx0 \
		mods/Qwan_Tatsunoko-Landscape.mod.zx0 \
		mods/Maak_in-my-memories.mod.zx0 \
		mods/MrGamer_Chipex-5.mod.zx0 \
		mods/Serpent_A-Hymn-to-Bacchus.mod.zx0 \
		mods/Impulsefus7_New-Entry.mod.zx0 \
		mods/Optic_Spank-my-Redux.mod.zx0 \
		mods/Rapture_Hurly-Burly-64.mod.zx0 \
		mods/Paula-Haunt_Carrot-Cake-Radio.mod.zx0 \
		mods/ASIKWUSpulse_Green-is-the-Color.mod.zx0 \
		mods/AdamJ_Joyful-Continuation.mod.zx0 \
		mods/Wertstahl_Always-Ahead.mod.zx0 \
		mods/Samplr_Stagnancy.mod.zx0 \
		mods/WOTW_Hypnotized.mod.zx0 \
		mods/Omniq_Nexus.mod.zx0 \
		mods/Getafix_Moves-Like-Jagger.mod.zx0 \
		mods/TNK_Lockdown-Liberation.mod.zx0 \
		mods/Cytron_The-More-Things.mod.zx0 \
		mods/Weezer_Melodie-II.mod.zx0 \
		mods/Comatron_k.i.s.s..mod.zx0 \
		mods/Remute_The-Carousel-of-Remute.mod.zx0 \
		mods/Woober_Short-Return.mod.zx0 \
		mods/ne7_banger.mod.zx0 \
		mods/Slaze_Hypertension.mod.zx0 \
		mods/TZX_The-Fleas-Got-The-Cat.mod.zx0 \
		mods/Danny-Mattissen_Twisted-Engine.mod.zx0 \
		mods/GWEM_Tea-at-Midnight.mod.zx0 \
		mods/tEIS_Turminchja.mod.zx0 \
		mods/Juice_Space-Jam.mod.zx0 \
		mods/Goto80_Jeffrix.mod.zx0 \
		mods/Mister-Roboto_LickMyBalls.mod.zx0 \
		mods/Mister-Roboto_Out-Of-My-House.mod.zx0 \
		mods/Akaobi_Restless-Blipper.mod.zx0 \
		mods/NOXW_20M40M80P.mod.zx0 \

data = $(tracks) \
			data/front.BPL \
			data/logo.BPL \
			data/bg-bottom-a.BPL \
			data/bg-bottom-b.BPL \
			data/checkbox.BPL \
			data/clouds-rept.BPL \
			data/scroll-bg.BPL \
			data/scroll.COP \
			data/font-8.bin \
			data/font-16.BPL \
			data/scroll-overlay-a.ASP \
			data/scroll-overlay-b.SPR \
			data/scroll-overlay-c.ASP \
			data/scroll-overlay-d.SPR \
			data/menu-logo.SPR \


all: $(adf)

run: $(adf)
	$(FSUAE) $(FSUAEFLAGS) $<

run-vamiga: $(adf)
	$(VAMIGA) $<

clean:
	@$(RM) $(elf_objects) $(hunk_objects) $(deps) $(adf) $(data)

.PHONY: all clean dist run run-vamiga

$(adf): launcher.bin bootblock.bin ui.bin.zx0 $(data) Makefile
	$(ADFTRACK) bootblock.bin $@ launcher.bin ui.bin.zx0 $(tracks)

# BUILD=hunk (vasm/vlink)
out/$(name).hunk.exe: $(hunk_objects) out/$(name).hunk-debug.exe
	$(info )
	$(info Linking (stripped) $@)
	@$(VLINK) $(VLINKFLAGS) -S $(hunk_objects) -o $@
	cp $@ $(program).exe
out/$(name).hunk-debug.exe: $(hunk_objects)
	$(info )
	$(info Linking $@)
	@$(VLINK) $(VLINKFLAGS) $(hunk_objects) -o $@
%.hunk : %.asm $(data)
	$(info )
	$(info Assembling $@)
	@$(VASM) $(VASMFLAGS) -Fhunk -linedebug -o $@ $(CURDIR)/$<

# BUILD=elf (GCC/Bartman)
out/$(name).elf.exe: $(program).elf
	$(info )
	$(info Elf2Hunk $@)
	@$(ELF2HUNK) $< $@ -s
	cp $@ $(program).exe
$(program).elf: $(elf_objects)
	$(info )
	$(info Linking $@)
	$(CC) $(CCFLAGS) $(LDFLAGS) $(elf_objects) -o $@
%.elf : %.asm $(data)
	$(info )
	$(info Assembling $<)
	@$(VASM) $(VASMFLAGS) -Felf -dwarf=3 -o $@ $(CURDIR)/$<

-include $(deps)

%.d : %.asm
	$(info Building dependencies for $<)
	$(VASM) $(VASMFLAGS) -quiet -dependall=make -o "$(patsubst %.d,%.bin,$@)" $< > $@
# $(VASM) $(VASMFLAGS) -quiet -dependall=make -o "$(patsubst %.d,%.\$$(BUILD),$@)" $< > $@

%.lsbank: %.mod
	$(LSPCONVERT) $< -getpos

%.lsmusic: %.mod
	$(LSPCONVERT) $< -getpos

%.zx0 : %
	$(SALVADOR) $< $@
	# $(ZX0) -f $<

%.bin : %.asm
	$(VASM) -Fbin -pic -o $@ $<


#-------------------------------------------------------------------------------
# Data:
#-------------------------------------------------------------------------------

data/front.BPL: assets/front.png
	$(KINGCON) $< data/front -F=5 -I -RP
data/front.PAL: data/front.BPL

data/logo.BPL: assets/logo.png
	$(KINGCON) $< data/logo -F=5 -I -M -C
data/logo.COP: data/logo.BPL

data/clouds-rept.BPL: assets/clouds-rept.png
	$(KINGCON) $< data/clouds-rept -F=5 -I
data/bg-bottom-a.BPL: assets/bg-bottom-a.png
	$(KINGCON) $< data/bg-bottom-a -F=5 -I
data/bg-bottom-b.BPL: assets/bg-bottom-b.png
	$(KINGCON) $< data/bg-bottom-b -F=5 -I
data/scroll-bg.BPL: assets/scroll-bg.png
	$(KINGCON) $< data/scroll-bg -F=3 -I -C
data/scroll.COP: assets/scroll-pal.png
	$(KINGCON) $< data/scroll -F=5 -C
data/checkbox.BPL: assets/checkbox.png
	$(KINGCON) $< data/checkbox -F=5 -I

data/scroll-overlay-a.ASP: assets/scroll-overlay-a.png 
	$(KINGCON) $< data/scroll-overlay-a -F=a16 -SX=168 -SY=258
data/scroll-overlay-b.SPR: assets/scroll-overlay-b.png 
	$(KINGCON) $< data/scroll-overlay-b -F=s16 -SX=184 -SY=258
data/scroll-overlay-c.ASP: assets/scroll-overlay-c.png 
	$(KINGCON) $< data/scroll-overlay-c -F=a16 -SX=312 -SY=258
data/scroll-overlay-d.SPR: assets/scroll-overlay-d.png 
	$(KINGCON) $< data/scroll-overlay-d -F=s16 -SX=328 -SY=258

data/menu-logo.SPR: assets/menu-logo.png 
	$(KINGCON) $< data/menu-logo -F=s16 -SX=430 -SY=224

data/font-8.bin: assets/font-8-mono.png
	$(AMIGECONV) -f bitplane -d 1 $< $@
data/font-16.BPL: assets/font-16.png
	$(KINGCON) $< data/font-16 -F=3 -I
