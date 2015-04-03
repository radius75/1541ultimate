
.PHONY: all mk1 mk2 prog special clean sw_clean loader

all:
	@svn up
	@$(MAKE) -C tools
	@$(MAKE) -C target/fpga -f makefile_700a
	@$(MAKE) -C target/fpga -f makefile_400a
	@$(MAKE) -C target/fpga -f makefile_250e
	@$(MAKE) -C target/software/1st_boot
	@$(MAKE) -C target/software/2nd_boot
	@$(MAKE) -C target/software/ultimate
	@$(MAKE) -C target/software/ultimate appl
	@$(MAKE) -C target/software/update FPGA400=1
	@cp target/software/update/result/update.bin .
	@cp target/software/ultimate/result/appl.bin .

mk2:
	@svn up
	@$(MAKE) -C legacy/2.6k/tools
	@$(MAKE) -C legacy/2.6k/target/fpga -f makefile_700a
	@$(MAKE) -C legacy/2.6k/target/software/1st_boot mk2
	@$(MAKE) -C legacy/2.6k/target/software/2nd_boot
	@$(MAKE) -C legacy/2.6k/target/software/ultimate
	@$(MAKE) -C legacy/2.6k/target/software/update FPGA400=0

mk3:
	@svn up
	@$(MAKE) -C tools
	@$(MAKE) -C target/fpga -f makefile_mb_700a
	@$(MAKE) -C target/software/mb_boot
	@$(MAKE) -C target/software/mb_boot2
	@$(MAKE) -C target/software/mb_lwip
	@$(MAKE) -C target/software/mb_ultimate
	@$(MAKE) -C target/software/mb_revert
	@$(MAKE) -C target/software/mb_update
	@$(MAKE) -C target/software/update_to_mb
	@cp target/software/update_to_mb/result/update.bin .
	@cp target/software/mb_revert/result/revert.u2u .
	@cp target/software/mb_update/result/update.u2u .

prog:
	@$(MAKE) mk2
	@$(MAKE) -C target/fpga -f makefile_boot_700a
	@$(MAKE) -C target/software/programmer
	@cp target/software/programmer/result/*.bit .

k1:
	@svn up
	@$(MAKE) -C tools
	@$(MAKE) -C target/fpga -f makefile_250e
	@$(MAKE) -C target/software/1st_boot mk1
	@$(MAKE) -C target/software/ultimate appl
	@cp target/software/ultimate/result/appl.bin .

prog:
	@$(MAKE) mk2
	@$(MAKE) -C target/fpga -f makefile_boot_700a
	@$(MAKE) -C target/software/programmer
	@cp target/software/programmer/result/*.bit .

special:
	@svn up
	@$(MAKE) -C target/fpga -f makefile_1400a
	@$(MAKE) -C target/fpga -f makefile_400a
	@$(MAKE) -C target/software/1st_boot special
	@$(MAKE) -C target/software/ultimate
	@echo "Bitfiles and application made.. No updater or such available."

loader:
	@$(MAKE) -C target/fpga -f makefile_boot_400a
	@$(MAKE) -C target/fpga -f makefile_boot_700a
	@$(MAKE) -C target/software/programmer
	@cp target/software/programmer/result/*.bit .

clean:
	@$(MAKE) -C tools clean
	@rm -f ./update.bin
	@rm -f ./flash_700.mcs
	@rm -rf target/fpga/work1400
	@rm -rf target/fpga/work400
	@rm -rf target/fpga/work700
	@rm -rf target/fpga/boot_700
	@rm -rf target/fpga/work250
	@rm -rf target/fpga/_xm*
	@rm -rf target/fpga/x*
	@rm -rf target/fpga/*.x*
	@rm -rf target/software/1st_boot/result
	@rm -rf target/software/1st_boot/output
	@rm -rf target/software/2nd_boot/result
	@rm -rf target/software/2nd_boot/output
	@rm -rf target/software/ultimate/result
	@rm -rf target/software/ultimate/output
	@rm -rf target/software/update/result
	@rm -rf target/software/update/output

sw_clean:
	@rm -rf target/software/1st_boot/result
	@rm -rf target/software/1st_boot/output
	@rm -rf target/software/2nd_boot/result
	@rm -rf target/software/2nd_boot/output
	@rm -rf target/software/ultimate/result
	@rm -rf target/software/ultimate/output
	@rm -rf target/software/update/result
	@rm -rf target/software/update/output
