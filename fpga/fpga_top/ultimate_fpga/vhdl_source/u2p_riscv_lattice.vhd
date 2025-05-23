-------------------------------------------------------------------------------
-- Title      : u2p_riscv
-- Author     : Gideon Zweijtzer <gideon.zweijtzer@gmail.com>
-------------------------------------------------------------------------------
-- Description: Toplevel based on the RiscV CPU core.
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.io_bus_pkg.all;
    use work.mem_bus_pkg.all;
    use work.my_math_pkg.all;
    use work.audio_type_pkg.all;
        
library ECP5U;
use ECP5U.components.all;

entity u2p_riscv_lattice is
generic (
    g_sampler        : boolean := true;
    g_sid            : boolean := true;
    g_dual_drive     : boolean := true );
port (
    -- (Optional) Oscillator
    CLOCK_50         : in    std_logic := '0';
    
    -- slot side
    SLOT_ADDR_OEn    : out   std_logic;
    SLOT_ADDR_DIR    : out   std_logic;
    SLOT_PHI2        : in    std_logic;
    SLOT_DOTCLK      : in    std_logic;
    SLOT_RSTn        : inout std_logic;
    SLOT_BUFFER_EN   : out   std_logic;
    SLOT_ADDR        : inout unsigned(15 downto 0);
    SLOT_DATA        : inout std_logic_vector(7 downto 0);
    SLOT_RWn         : inout std_logic;
    SLOT_BA          : in    std_logic;
    SLOT_DMAn        : out   std_logic;
    SLOT_EXROMn      : inout std_logic;
    SLOT_GAMEn       : inout std_logic;
    SLOT_ROMHn       : in    std_logic;
    SLOT_ROMLn       : in    std_logic;
    SLOT_IO1n        : in    std_logic;
    SLOT_IO2n        : in    std_logic;
    SLOT_IRQn        : inout std_logic;
    SLOT_NMIn        : inout std_logic;
    SLOT_VCC         : in    std_logic;
    SLOT_DRV_RST     : out   std_logic := '0';
    
    -- memory
    SDRAM_A     : out   std_logic_vector(13 downto 0); -- DRAM A
    SDRAM_BA    : out   std_logic_vector(2 downto 0) := (others => '0');
    SDRAM_DQ    : inout std_logic_vector(7 downto 0);
    SDRAM_DM    : inout std_logic;
    SDRAM_CSn   : out   std_logic;
    SDRAM_RASn  : out   std_logic;
    SDRAM_CASn  : out   std_logic;
    SDRAM_WEn   : out   std_logic;
    SDRAM_CKE   : out   std_logic;
    SDRAM_CLK   : inout std_logic;
    SDRAM_CLKn  : inout std_logic;
    SDRAM_ODT   : out   std_logic;
    SDRAM_DQS   : inout std_logic;
     
    AUDIO_MCLK  : out   std_logic := '0';
    AUDIO_BCLK  : out   std_logic := '0';
    AUDIO_LRCLK : out   std_logic := '0';
    AUDIO_SDO   : out   std_logic := '0';
    AUDIO_SDI   : in    std_logic;

    -- Pin  1: GND    | 1.8V     Pin  2
    -- Pin  3: TMS    | DBG_TRST Pin  4
    -- Pin  5: TDI    | DBG_TDO  Pin  6
    -- Pin  7: TCK    | DBG_TDI  Pin  8
    -- Pin  9: TDO    | DBG_TCK  Pin 10
    -- Pin 11: SPARE  | DBG_TMS  Pin 12
    -- Pin 13: +3.3V  | GND      Pin 14

    -- Clock Module:
    -- RESON_OUT -> pin 11 -> SPARE
    -- JITTERY   -> pin 12 -> DBG_TMS
    -- CLKOUT1   -> pin  8 -> DBG_TDI
    -- SDA       -> pin  6 -> DBG_TDO
    -- SCL       -> pin  4 -> DBG_TRST

    -- Clock module
    -- DEBUG_TRSTn : inout std_logic;        -- Header PIN 4
    -- DEBUG_TDO   : inout std_logic;        -- Header PIN 6
    -- DEBUG_SPARE : out   std_logic := '1'; -- Header PIN 11
    -- DEBUG_TDI   : in    std_logic := '1'; -- Header PIN 8
    -- DEBUG_TCK   : out   std_logic := '1'; -- Header PIN 10
    -- DEBUG_TMS   : out   std_logic := '1'; -- Header PIN 12

    -- WiFi module
    DEBUG_SPARE : out   std_logic; -- Header PIN 11
    DEBUG_TRSTn : out   std_logic; -- Header PIN 4
    DEBUG_TDI   : out   std_logic; -- Header PIN 8
    DEBUG_TDO   : in    std_logic := '1'; -- Header PIN 6
    DEBUG_TCK   : out   std_logic; -- Header PIN 10
    DEBUG_TMS   : in    std_logic := '1'; -- Header PIN 12

    UNUSED_G12  : out   std_logic; -- not on test pad
    UNUSED_H3   : out   std_logic;
    UNUSED_F4   : out   std_logic;

    -- IEC bus
    IEC_ATN_O   : out   std_logic;
    IEC_DATA_O  : out   std_logic;
    IEC_CLOCK_O : out   std_logic;
    IEC_RESET_O : out   std_logic;
    IEC_SRQ_O   : out   std_logic;

    IEC_ATN_I   : in    std_logic;
    IEC_DATA_I  : in    std_logic;
    IEC_CLOCK_I : in    std_logic;
    IEC_RESET_I : in    std_logic;
    IEC_SRQ_I   : in    std_logic;
    
    LED_DISKn   : out   std_logic; -- activity LED
    LED_CARTn   : out   std_logic;
    LED_SDACTn  : out   std_logic;
    LED_MOTORn  : out   std_logic;
    
    -- Ethernet RMII
    ETH_RESETn      : out std_logic := '1';
    ETH_IRQn        : in  std_logic;
    
    RMII_REFCLK     : in  std_logic;
    RMII_CRS_DV     : in  std_logic;
    RMII_RX_ER      : in  std_logic;
    RMII_RX_DATA    : in  std_logic_vector(1 downto 0);
    RMII_TX_DATA    : out std_logic_vector(1 downto 0);
    RMII_TX_EN      : out std_logic;

    MDIO_CLK    : out   std_logic := '0';
    MDIO_DATA   : inout std_logic := 'Z';

    -- Speaker data
    SPEAKER_DATA    : out std_logic := '0';
    SPEAKER_ENABLE  : out std_logic := '0';

    -- Debug UART
    UART_TXD    : out   std_logic;
    UART_RXD    : in    std_logic;
    
    -- USB Experiment
    USB_DP      : inout std_logic;
    USB_DM      : inout std_logic;
    USB_PULLUP  : out   std_logic;
    
    -- I2C Interface for RTC, audio codec and usb hub
    I2C_SDA     : inout std_logic := 'Z';
    I2C_SCL     : inout std_logic := 'Z';
    I2C_SDA_18  : inout std_logic := 'Z';
    I2C_SCL_18  : inout std_logic := 'Z';

    -- Flash Interface
    FLASH_CSn   : out   std_logic;
--    FLASH_SCK   : out   std_logic;
    FLASH_MOSI  : out   std_logic;
    FLASH_MISO  : in    std_logic;

    -- USB Interface (ULPI)
    ULPI_REFCLK : out   std_logic;
    ULPI_RESET  : out   std_logic;
    ULPI_CLOCK  : in    std_logic;
    ULPI_NXT    : in    std_logic;
    ULPI_STP    : out   std_logic;
    ULPI_DIR    : in    std_logic;
    ULPI_DATA   : inout std_logic_vector(7 downto 0);

    HUB_RESETn  : out   std_logic := '1';
    HUB_CLOCK   : out   std_logic := '0';

	-- Misc
	BOARD_REVn  : in    std_logic_vector(4 downto 0);

    -- Cassette Interface
    CAS_MOTOR   : in    std_logic := '0';
    CAS_SENSE   : inout std_logic;
    CAS_READ    : inout std_logic;
    CAS_WRITE   : inout std_logic;
    
    -- Buttons
    BUTTON      : in    std_logic_vector(2 downto 0));

end entity;

architecture rtl of u2p_riscv_lattice is

    signal flash_sck_o  : std_logic;
    signal flash_sck_t  : std_logic;
    signal mem_ready    : std_logic;
    signal RSTn_out     : std_logic;
    signal irq_oc, nmi_oc, dma_oc, exrom_oc, game_oc    : std_logic;
    signal slot_addr_o  : unsigned(15 downto 0);
    signal slot_addr_tl : std_logic;
    signal slot_addr_th : std_logic;
    signal slot_data_o  : std_logic_vector(7 downto 0);
    signal slot_data_t  : std_logic;
    signal slot_rwn_o   : std_logic;
    
    signal start_clock  : std_logic;
    signal start_reset  : std_logic;
    signal half_clock   : std_logic;
    signal mem_clock    : std_logic;
    signal toggle_reset : std_logic;
    signal toggle_check : std_logic;
    signal ctrl_clock   : std_logic;
    signal ctrl_reset   : std_logic;
    signal sys_clock    : std_logic;
    signal sys_reset    : std_logic := '1';
    signal clock_24     : std_logic;
    signal audio_clock  : std_logic;
    signal audio_reset  : std_logic;
    signal eth_clock    : std_logic;
    signal eth_reset    : std_logic;
    signal ulpi_reset_req : std_logic;
    signal button_i     : std_logic_vector(2 downto 0);
    signal buffer_en    : std_logic;
    signal toggle       : std_logic;
    signal slot_dot_clock_f : std_logic;

    -- miscellaneous interconnect
    signal ulpi_reset_i     : std_logic;
    signal ulpi_data_o      : std_logic_vector(7 downto 0);
    signal ulpi_data_t      : std_logic;
    signal ulpi_data_i      : std_logic_vector(7 downto 0);
    signal ulpi_nxt_i       : std_logic;
    signal ulpi_dir_i       : std_logic;
        
    -- memory controller interconnect
    signal mem_inhibit_1x   : std_logic;
    signal mem_inhibit_2x   : std_logic;
    signal cpu_mem_req      : t_mem_req_32;
    signal cpu_mem_resp     : t_mem_resp_32;
    signal mem_req          : t_mem_req_32;
    signal mem_resp         : t_mem_resp_32;
    signal mem_req_2x       : t_mem_req_32;
    signal mem_resp_2x      : t_mem_resp_32;

    signal i2c_sda_i   : std_logic;
    signal i2c_sda_o   : std_logic;
    signal i2c_scl_i   : std_logic;
    signal i2c_scl_o   : std_logic;
    signal mdio_o      : std_logic;

    signal sw_trigger     : std_logic;
    signal trigger     : std_logic;
        
    -- IEC open drain and inversions
    signal sw_iec_o    : std_logic_vector(3 downto 0);
    signal sw_iec_i    : std_logic_vector(3 downto 0);
    signal ult_atn_o   : std_logic; 
    signal ult_data_o  : std_logic;
    signal ult_clock_o : std_logic;
    signal ult_reset_o : std_logic;
    signal ult_srq_o   : std_logic;
    
    -- Cassette
    signal c2n_read_in      : std_logic;
    signal c2n_write_in     : std_logic;
    signal c2n_read_out     : std_logic;
    signal c2n_write_out    : std_logic;
    signal c2n_read_en      : std_logic;
    signal c2n_write_en     : std_logic;
    signal c2n_sense_in     : std_logic;
    signal c2n_sense_out    : std_logic;
    signal c2n_motor_in     : std_logic;
    signal c2n_motor_out    : std_logic;

    -- io buses
    signal io_irq       : std_logic;
    signal io_req_riscv : t_io_req;
    signal io_resp_riscv: t_io_resp;
    signal io_req       : t_io_req;
    signal io_resp      : t_io_resp;
    signal io_u2p_req   : t_io_req;
    signal io_u2p_resp  : t_io_resp;
    signal io_u2p_req_small : t_io_req;
    signal io_u2p_resp_small: t_io_resp;
    signal io_u2p_req_big   : t_io_req;
    signal io_u2p_resp_big  : t_io_resp;
    signal io_req_new_io    : t_io_req;
    signal io_resp_new_io   : t_io_resp;
    signal io_req_remote    : t_io_req;
    signal io_resp_remote   : t_io_resp;
    signal io_req_ddr2      : t_io_req;
    signal io_resp_ddr2     : t_io_resp;

    signal io_req_mixer     : t_io_req;
    signal io_resp_mixer    : t_io_resp;
    signal io_req_debug     : t_io_req;
    signal io_resp_debug    : t_io_resp;

    -- Parallel cable connection
    signal drv_track_is_0       : std_logic;
    signal drv_via1_port_a_o    : std_logic_vector(7 downto 0);
    signal drv_via1_port_a_i    : std_logic_vector(7 downto 0);
    signal drv_via1_port_a_t    : std_logic_vector(7 downto 0);
    signal drv_via1_ca2_o       : std_logic;
    signal drv_via1_ca2_i       : std_logic;
    signal drv_via1_ca2_t       : std_logic;
    signal drv_via1_cb1_o       : std_logic;
    signal drv_via1_cb1_i       : std_logic;
    signal drv_via1_cb1_t       : std_logic;
    
    -- audio
    signal audio_speaker    : signed(12 downto 0);
    signal speaker_vol      : std_logic_vector(3 downto 0);

    signal ult_drive1       : signed(17 downto 0);
    signal ult_drive2       : signed(17 downto 0);
    signal ult_tape_r       : signed(17 downto 0);
    signal ult_tape_w       : signed(17 downto 0);
    signal ult_samp_l       : signed(17 downto 0);
    signal ult_samp_r       : signed(17 downto 0);
    signal ult_sid_1        : signed(17 downto 0);
    signal ult_sid_2        : signed(17 downto 0);

    signal c64_debug_select : std_logic_vector(2 downto 0);
    signal c64_debug_data   : std_logic_vector(31 downto 0);
    signal c64_debug_valid  : std_logic;
    signal drv_debug_data   : std_logic_vector(31 downto 0);
    signal drv_debug_valid  : std_logic;
    
    signal rmii_tx_en_i     : std_logic;
    signal rmii_tx_data_i   : std_logic_vector(1 downto 0);
    signal rmii_crs_dv_i    : std_logic;
    signal rmii_rx_data_i   : std_logic_vector(1 downto 0);
    signal rmii_crs_dv_d    : std_logic;
    signal rmii_rx_data_d   : std_logic_vector(1 downto 0);

    signal eth_tx_data   : std_logic_vector(7 downto 0);
    signal eth_tx_last   : std_logic;
    signal eth_tx_valid  : std_logic;
    signal eth_tx_ready  : std_logic := '1';

    signal eth_u2p_data  : std_logic_vector(7 downto 0);
    signal eth_u2p_last  : std_logic;
    signal eth_u2p_valid : std_logic;
    signal eth_u2p_ready : std_logic := '1';

    signal eth_rx_data   : std_logic_vector(7 downto 0);
    signal eth_rx_sof    : std_logic;
    signal eth_rx_eof    : std_logic;
    signal eth_rx_valid  : std_logic;

    signal phase_sel     : std_logic_vector(1 downto 0);
    signal phase_dir     : std_logic;
    signal phase_step    : std_logic;
    signal phase_loadreg : std_logic;
    signal all_buttons   : std_logic;
    signal ctrl_reset_pulse : std_logic;
    signal wifi_boot        : std_logic;
    signal wifi_enable      : std_logic;
begin
    ctrl_clock  <= half_clock;
    HUB_CLOCK   <= clock_24;
    ULPI_REFCLK <= clock_24;
    all_buttons <= '1' when button_i = "111" else '0';

    i_ulpi_reset: entity work.level_synchronizer
    generic map ('1')
    port map (
        clock       => ulpi_clock,
        input       => ulpi_reset_req,
        input_c     => ulpi_reset_i  );

    i_startup: entity work.startup
    port map (
        ref_clock     => RMII_REFCLK,
        phase_sel     => phase_sel,
        phase_dir     => phase_dir,
        phase_step    => phase_step,
        phase_loadreg => phase_loadreg,
        start_clock   => start_clock,
        start_reset   => start_reset,
        mem_clock     => mem_clock,
        mem_ready     => mem_ready,
        ctrl_clock    => ctrl_clock,
        ctrl_reset    => ctrl_reset,
        restart       => ctrl_reset_pulse,
        button        => all_buttons,
        sys_clock     => sys_clock,
        sys_reset     => sys_reset,
        audio_clock   => audio_clock,
        audio_reset   => audio_reset,
        eth_clock     => eth_clock,
        eth_reset     => eth_reset,
        clock_24      => clock_24
    );
    

    -- i_riscv: entity work.neorv32_wrapper
    -- generic map (
    --     g_jtag_debug=> g_jtag_debug,
    --     g_frequency => 50_000_000,
    --     g_tag       => X"20"
    -- )
    -- port map (
    --     clock       => sys_clock,
    --     reset       => sys_reset,
    --     cpu_reset   => '0',
    --     jtag_trst_i => DEBUG_TRSTn,
    --     jtag_tck_i  => DEBUG_TCK,
    --     jtag_tdi_i  => DEBUG_TDI,
    --     jtag_tdo_o  => DEBUG_TDO,
    --     jtag_tms_i  => DEBUG_TMS,
    --     timeout     => open,--LED_SDACTn,
    --     irq_i       => io_irq,
    --     irq_o       => open,
    --     io_req      => io_req_riscv,
    --     io_resp     => io_resp_riscv,
    --     io_busy     => open,
    --     mem_req     => cpu_mem_req,
    --     mem_resp    => cpu_mem_resp
    -- );
    
    i_riscv: entity work.rvlite_wrapper
    port map (
        clock       => sys_clock,
        reset       => sys_reset,
        irq_i       => io_irq,
        io_req      => io_req_riscv,
        io_resp     => io_resp_riscv,
        io_busy     => open,
        mem_req     => cpu_mem_req,
        mem_resp    => cpu_mem_resp
    );

    i_u2p_io_split: entity work.io_bus_splitter
    generic map (
        g_range_lo => 20,
        g_range_hi => 20,
        g_ports    => 2
    )
    port map(
        clock      => sys_clock,
        req        => io_req_riscv,
        resp       => io_resp_riscv,
        reqs(0)    => io_req,
        reqs(1)    => io_u2p_req,
        resps(0)   => io_resp,
        resps(1)   => io_u2p_resp
    );

    i_split_u2p: entity work.io_bus_splitter
    generic map (
        g_range_lo => 16,
        g_range_hi => 16,
        g_ports    => 2
    )
    port map (
        clock      => sys_clock,
        req        => io_u2p_req,
        resp       => io_u2p_resp,
        reqs(0)    => io_u2p_req_small,
        reqs(1)    => io_u2p_req_big,
        resps(0)   => io_u2p_resp_small,
        resps(1)   => io_u2p_resp_big
    );

    i_split: entity work.io_bus_splitter
    generic map (
        g_range_lo => 8,
        g_range_hi => 9,
        g_ports    => 3
    )
    port map (
        clock      => sys_clock,
        req        => io_u2p_req_small,
        resp       => io_u2p_resp_small,
        reqs(0)    => io_req_new_io,
        reqs(1)    => io_req_ddr2,
        reqs(2)    => io_req_remote,
        resps(0)   => io_resp_new_io,
        resps(1)   => io_resp_ddr2,
        resps(2)   => io_resp_remote
    );

    i_split2: entity work.io_bus_splitter
    generic map (
        g_range_lo => 12,
        g_range_hi => 12,
        g_ports    => 2
    )
    port map (
        clock      => sys_clock,
        req        => io_u2p_req_big,
        resp       => io_u2p_resp_big,
        reqs(0)    => io_req_mixer,
        reqs(1)    => io_req_debug,
        resps(0)   => io_resp_mixer,
        resps(1)   => io_resp_debug
    );

    i_double_freq_bridge: entity work.memreq_halfrate2
    port map(
        phase_out   => toggle_check,
        toggle_r_2x => toggle_reset,
        clock_1x    => sys_clock,
        clock_2x    => ctrl_clock,
        reset_1x    => sys_reset,
        mem_req_1x  => mem_req,
        mem_resp_1x => mem_resp,
        inhibit_1x  => mem_inhibit_1x,
        mem_req_2x  => mem_req_2x,
        mem_resp_2x => mem_resp_2x,
        inhibit_2x  => mem_inhibit_2x
    );

    i_memctrl: entity work.ddr2_ctrl
    port map (
        start_clock       => start_clock,
        start_reset       => start_reset,
        start_ready       => mem_ready,
        mem_clock         => mem_clock,
        mem_clock_half    => half_clock,
        
        toggle_reset      => toggle_reset,
        toggle_check      => toggle_check,

        sys_clock         => sys_clock,
        ctrl_clock        => ctrl_clock,
        ctrl_reset        => ctrl_reset,
        req               => mem_req_2x,
        resp              => mem_resp_2x,
        inhibit           => mem_inhibit_2x,
        reset_out         => ctrl_reset_pulse,
        
        io_clock          => sys_clock,
        io_reset          => sys_reset,
        io_req            => io_req_ddr2,
        io_resp           => io_resp_ddr2,

        phase_sel         => phase_sel, 
        phase_dir         => phase_dir, 
        phase_step        => phase_step, 
        phase_loadreg     => phase_loadreg, 

        SDRAM_TEST1       => UNUSED_G12,
        SDRAM_TEST2       => open,
        SDRAM_CLK         => SDRAM_CLK,
        SDRAM_CLKn        => SDRAM_CLKn,
        SDRAM_CKE         => SDRAM_CKE,
        SDRAM_ODT         => SDRAM_ODT,
        SDRAM_CSn         => SDRAM_CSn,
        SDRAM_RASn        => SDRAM_RASn,
        SDRAM_CASn        => SDRAM_CASn,
        SDRAM_WEn         => SDRAM_WEn,
        SDRAM_A           => SDRAM_A,
        SDRAM_BA          => SDRAM_BA,
        SDRAM_DM          => SDRAM_DM,
        SDRAM_DQ          => SDRAM_DQ,
        SDRAM_DQS         => SDRAM_DQS
    );
    UNUSED_F4 <= '0';

    i_remote_dummy: entity work.io_dummy
    port map(
        clock   => sys_clock,
        io_req  => io_req_remote,
        io_resp => io_resp_remote
    );

    i_u2p_io: entity work.u2p_io
    port map (
        clock      => sys_clock,
        reset      => sys_reset,
        io_req     => io_req_new_io,
        io_resp    => io_resp_new_io,
        mdc        => MDIO_CLK,
        mdio_i     => MDIO_DATA,
        mdio_o     => mdio_o,
        i2c_scl_i  => i2c_scl_i,
        i2c_scl_o  => i2c_scl_o,
        i2c_sda_i  => i2c_sda_i,
        i2c_sda_o  => i2c_sda_o,
        iec_i      => sw_iec_i,
        iec_o      => sw_iec_o,

        board_rev  => not BOARD_REVn,
        eth_irq_i  => ETH_IRQn,
        speaker_en => SPEAKER_ENABLE,
	    speaker_vol=> speaker_vol,
        hub_reset_n=> HUB_RESETn,
        ulpi_reset => ulpi_reset_req,
        buffer_en  => buffer_en
    );

    i2c_scl_i   <= I2C_SCL and I2C_SCL_18;
    i2c_sda_i   <= I2C_SDA and I2C_SDA_18;
    I2C_SCL     <= '0' when i2c_scl_o = '0' else 'Z';
    I2C_SDA     <= '0' when i2c_sda_o = '0' else 'Z';
    I2C_SCL_18  <= '0' when i2c_scl_o = '0' else 'Z';
    I2C_SDA_18  <= '0' when i2c_sda_o = '0' else 'Z';
    MDIO_DATA   <= '0' when mdio_o = '0' else 'Z';

    i_logic: entity work.ultimate_logic_32
    generic map (
        g_simulation    => false,
        g_ultimate2plus => true,
        g_fpga_type     => 1,
        g_clock_freq    => 50_000_000,
        g_numerator     => 8,
        g_denominator   => 25,
        g_baud_rate     => 115_200,
        g_big_endian    => false,
        g_icap          => false,
        g_uart          => true,
        g_uart_rx       => false,
        g_drive_1541    => true,
        g_drive_1541_2  => g_dual_drive,
        g_mm_drive      => true,
        g_hardware_gcr  => true,
        g_ram_expansion => true,
        g_extended_reu  => false,
        g_stereo_sid    => g_sid,
        g_8voices       => false,
        g_hardware_iec  => true,
        g_c2n_streamer  => true,
        g_c2n_recorder  => true,
        g_cartridge     => true,
        g_cartreset_init => '1',
        g_register_addr => true, -- to meet timing. Causes address to be sampled one clock BEFORE do_sample_addr!
        g_command_intf  => true,
        g_drive_sound   => true,
        g_rtc_chip      => false,
        g_rtc_timer     => false,
        g_usb_host2     => true,
        g_spi_flash     => true,
        g_vic_copper    => false,
        g_wifi_uart     => true,
        g_sampler       => g_sampler,
        g_sampler_16bit => true,
        g_sampler_voices=> 8,
        g_acia          => true,
        g_rmii          => true )
    port map (
        -- globals
        sys_clock   => sys_clock,
        sys_reset   => sys_reset,
    
        ulpi_clock  => ulpi_clock,
        ulpi_reset  => ulpi_reset_i,
    
        ext_io_req  => io_req,
        ext_io_resp => io_resp,
        ext_mem_req => cpu_mem_req,
        ext_mem_resp=> cpu_mem_resp,
        cpu_irq     => io_irq,
        
        -- slot side
        BUFFER_ENn  => open,
        VCCDET      => SLOT_VCC,

        phi2_i      => not SLOT_PHI2, -- 74LV14
        dotclk_i    => SLOT_DOTCLK,
        rstn_i      => SLOT_RSTn,
        rstn_o      => RSTn_out,
                                   
        slot_addr_o => slot_addr_o,
        slot_addr_i => SLOT_ADDR,
        slot_addr_tl=> slot_addr_tl,
        slot_addr_th=> slot_addr_th,
        slot_data_o => slot_data_o,
        slot_data_i => SLOT_DATA,
        slot_data_t => slot_data_t,
        rwn_i       => SLOT_RWn,
        rwn_o       => slot_rwn_o,
        exromn_i    => SLOT_EXROMn,
        exromn_o    => exrom_oc,
        gamen_i     => SLOT_GAMEn,
        gamen_o     => game_oc,
        irqn_i      => SLOT_IRQn,
        irqn_o      => irq_oc,
        nmin_i      => SLOT_NMIn,
        nmin_o      => nmi_oc,
        ba_i        => SLOT_BA,
        dman_o      => dma_oc,
        romhn_i     => SLOT_ROMHn,
        romln_i     => SLOT_ROMLn,
        io1n_i      => SLOT_IO1n,
        io2n_i      => SLOT_IO2n,
                
        -- local bus side
        mem_refr_inhibit => mem_inhibit_1x,
        mem_req     => mem_req,
        mem_resp    => mem_resp,
                 
        -- Audio outputs
        audio_speaker   => audio_speaker,
        speaker_vol     => speaker_vol,

        aud_drive1      => ult_drive1, 
        aud_drive2      => ult_drive2, 
        aud_tape_r      => ult_tape_r, 
        aud_tape_w      => ult_tape_w, 
        aud_samp_l      => ult_samp_l, 
        aud_samp_r      => ult_samp_r, 
        aud_sid_1       => ult_sid_1,
        aud_sid_2       => ult_sid_2,
        
        -- IEC bus
        iec_reset_i => not IEC_RESET_I, -- 74LV14
        iec_atn_i   => not IEC_ATN_I,   -- 74LV14
        iec_data_i  => not IEC_DATA_I,  -- 74LV14
        iec_clock_i => not IEC_CLOCK_I, -- 74LV14
        iec_srq_i   => not IEC_SRQ_I,   -- 74LV14
                                  
        iec_reset_o => ult_reset_o,
        iec_atn_o   => ult_atn_o,
        iec_data_o  => ult_data_o,
        iec_clock_o => ult_clock_o,
        iec_srq_o   => ult_srq_o,
                                    
        MOTOR_LEDn  => LED_MOTORn,
        DISK_ACTn   => LED_DISKn,
        CART_LEDn   => LED_CARTn,
        SDACT_LEDn  => LED_SDACTn,

        -- Parallel cable pins
        drv_track_is_0      => drv_track_is_0,
        drv_via1_port_a_o   => drv_via1_port_a_o,
        drv_via1_port_a_i   => drv_via1_port_a_i,
        drv_via1_port_a_t   => drv_via1_port_a_t,
        drv_via1_ca2_o      => drv_via1_ca2_o,
        drv_via1_ca2_i      => drv_via1_ca2_i,
        drv_via1_ca2_t      => drv_via1_ca2_t,
        drv_via1_cb1_o      => drv_via1_cb1_o,
        drv_via1_cb1_i      => drv_via1_cb1_i,
        drv_via1_cb1_t      => drv_via1_cb1_t,

        -- Debug UART
        UART_TXD    => UART_TXD,
        UART_RXD    => UART_RXD,
        
        -- WiFi UART
        WIFI_BOOT     => wifi_boot,   -- DEBUG_SPARE, -- pin 11
        WIFI_ENABLE   => wifi_enable, -- DEBUG_TRSTn, -- pin 4
        WIFI_TXD      => DEBUG_TDI,   -- pin 8
        WIFI_RXD      => DEBUG_TDO,   -- pin 6
        WIFI_RTS      => DEBUG_TCK,   -- pin 10
        WIFI_CTS      => DEBUG_TMS,   -- pin 12

        -- Debug buses
        drv_debug_data   => drv_debug_data,
        drv_debug_valid  => drv_debug_valid,
        c64_debug_data   => c64_debug_data,
        c64_debug_valid  => c64_debug_valid,
        c64_debug_select => c64_debug_select,                    
        
        -- SD Card Interface
        SD_SSn      => open,
        SD_CLK      => open,
        SD_MOSI     => open,
        SD_MISO     => '1',
        SD_CARDDETn => '1',
        
        -- RTC Interface
        RTC_CS      => open,
        RTC_SCK     => open,
        RTC_MOSI    => open,
        RTC_MISO    => '1',
    
        -- Flash Interface
        FLASH_CSn   => FLASH_CSn,
        FLASH_SCK   => flash_sck_o,
        FLASH_MOSI  => FLASH_MOSI,
        FLASH_MISO  => FLASH_MISO,
    
        -- USB Interface (ULPI)
        ULPI_NXT    => ulpi_nxt_i,
        ULPI_DIR    => ulpi_dir_i,
        ULPI_STP    => ULPI_STP,
        ULPI_DATA_O => ulpi_data_o,
        ULPI_DATA_I => ulpi_data_i,
        ULPI_DATA_T => ulpi_data_t,
    
        -- Cassette Interface
        c2n_read_in    => c2n_read_in, 
        c2n_write_in   => c2n_write_in, 
        c2n_read_out   => c2n_read_out, 
        c2n_write_out  => c2n_write_out, 
        c2n_read_en    => c2n_read_en, 
        c2n_write_en   => c2n_write_en, 
        c2n_sense_in   => c2n_sense_in, 
        c2n_sense_out  => c2n_sense_out, 
        c2n_motor_in   => c2n_motor_in, 
        c2n_motor_out  => c2n_motor_out, 
        
        -- Ethernet Interface (RMII)
        eth_clock    => eth_clock, 
        eth_reset    => eth_reset,
        eth_rx_data  => eth_rx_data,
        eth_rx_sof   => eth_rx_sof,
        eth_rx_eof   => eth_rx_eof,
        eth_rx_valid => eth_rx_valid,
        eth_tx_data  => eth_u2p_data,
        eth_tx_eof   => eth_u2p_last,
        eth_tx_valid => eth_u2p_valid,
        eth_tx_ready => eth_u2p_ready,

        -- Buttons
        sw_trigger  => sw_trigger,
        BUTTON      => button_i );

    DEBUG_SPARE <= '0' when wifi_boot = '0' else 'Z';
    DEBUG_TRSTn <= '0' when wifi_enable = '0' else 'Z';

    IEC_ATN_O   <= not ult_atn_o;
    IEC_DATA_O  <= not ult_data_o;
    IEC_CLOCK_O <= not ult_clock_o;
    IEC_RESET_O <= not ult_reset_o;
    IEC_SRQ_O   <= not ult_srq_o;

    ULPI_DATA <= ulpi_data_o when ulpi_data_t = '1' else "ZZZZZZZZ";
    r: for i in ULPI_DATA'range generate
        i_delay: DELAYG generic map (DEL_MODE => "SCLK_ZEROHOLD") port map (A => ULPI_DATA(i), Z => ulpi_data_i(i));
        --i_delay: DELAYG generic map (DEL_VALUE => "DELAY5") port map (A => ULPI_DATA(i), Z => ulpi_data_delayed(i));
    end generate;
    i_delay_ulpi_nxt: DELAYG generic map (DEL_MODE => "SCLK_ZEROHOLD") port map (A => ULPI_NXT, Z => ulpi_nxt_i);
    i_delay_ulpi_dir: DELAYG generic map (DEL_MODE => "USER_DEFINED", DEL_VALUE => 5) port map (A => ULPI_DIR, Z => ulpi_dir_i);

    -- Parallel cable not implemented. This is the way to stub it...
    drv_via1_port_a_i(7 downto 1) <= drv_via1_port_a_o(7 downto 1) or not drv_via1_port_a_t(7 downto 1);
    drv_via1_port_a_i(0)          <= drv_track_is_0; -- for 1541C
    drv_via1_ca2_i    <= drv_via1_ca2_o    or not drv_via1_ca2_t;
    drv_via1_cb1_i    <= drv_via1_cb1_o    or not drv_via1_cb1_t;

    u1: USRMCLK
    port map (
        USRMCLKI => flash_sck_o,
        USRMCLKTS => flash_sck_t
    );

    process(sys_clock)
        variable c, d  : std_logic := '0';
    begin
        if rising_edge(sys_clock) then
            trigger <= d;
            d := c;
            c := button_i(0);
        end if;
    end process;
    
    SLOT_RSTn <= '0' when RSTn_out = '0' else 'Z';
    SLOT_DRV_RST <= not RSTn_out when rising_edge(sys_clock); -- Drive this pin HIGH when we want to reset the C64 (uses NFET on Rev.E boards)
    
    SLOT_ADDR(15 downto 12) <= slot_addr_o(15 downto 12) when slot_addr_th = '1' else (others => 'Z');
    SLOT_ADDR(11 downto 00) <= slot_addr_o(11 downto 00) when slot_addr_tl = '1' else (others => 'Z');
    SLOT_DATA <= slot_data_o when slot_data_t = '1' else (others => 'Z');
    SLOT_RWn  <= slot_rwn_o  when slot_addr_tl = '1' else 'Z';

    irq_push: entity work.oc_pusher port map(clock => sys_clock, sig_in => irq_oc, oc_out => SLOT_IRQn);
    nmi_push: entity work.oc_pusher port map(clock => sys_clock, sig_in => nmi_oc, oc_out => SLOT_NMIn);
    dma_push: entity work.oc_pusher port map(clock => sys_clock, sig_in => dma_oc, oc_out => SLOT_DMAn);
    exr_push: entity work.oc_pusher port map(clock => sys_clock, sig_in => exrom_oc, oc_out => SLOT_EXROMn);
    gam_push: entity work.oc_pusher port map(clock => sys_clock, sig_in => game_oc, oc_out => SLOT_GAMEn);
    
--    IEC_SRQ_IN <= '0' when iec_srq_o   = '0' or sw_iec_o(3) = '0' else 'Z';
--    IEC_ATN    <= '0' when iec_atn_o   = '0' or sw_iec_o(2) = '0' else 'Z';
--    IEC_DATA   <= '0' when iec_data_o  = '0' or sw_iec_o(1) = '0' else 'Z';
--    IEC_CLOCK  <= '0' when iec_clock_o = '0' or sw_iec_o(0) = '0' else 'Z';

    sw_iec_i <= IEC_SRQ_I & IEC_ATN_I & IEC_DATA_I & IEC_CLOCK_I;

    button_i <= not BUTTON;

    ULPI_RESET <= not sys_reset; --por_n;

    -- Tape
    c2n_motor_in <= CAS_MOTOR;
    CAS_SENSE    <= '0' when c2n_sense_out = '1' else 'Z';
    c2n_sense_in <= not CAS_SENSE;
    CAS_READ     <= c2n_read_out when c2n_read_en = '1' else 'Z';
    c2n_read_in  <= CAS_READ;
    CAS_WRITE    <= c2n_write_out when c2n_write_en = '1' else 'Z';
    c2n_write_in <= CAS_WRITE;


    i_pwm0: entity work.sigma_delta_dac --delta_sigma_2to5
    generic map (
        g_left_shift => 2,
        g_divider => 10,
        g_width => audio_speaker'length )
    port map (
        clock   => sys_clock,
        reset   => sys_reset,
        
        dac_in  => audio_speaker,
    
        dac_out => SPEAKER_DATA );

    b_audio: block        
        signal aud_drive1       : signed(17 downto 0);
        signal aud_drive2       : signed(17 downto 0);
        signal aud_tape_r       : signed(17 downto 0);
        signal aud_tape_w       : signed(17 downto 0);
        signal aud_samp_l       : signed(17 downto 0);
        signal aud_samp_r       : signed(17 downto 0);
        signal aud_sid_1        : signed(17 downto 0);
        signal aud_sid_2        : signed(17 downto 0);
        signal codec_left_in    : std_logic_vector(23 downto 0);
        signal codec_right_in   : std_logic_vector(23 downto 0);
        signal codec_left_out   : std_logic_vector(23 downto 0);
        signal codec_right_out  : std_logic_vector(23 downto 0);
        signal audio_get_sample : std_logic;
        signal sys_get_sample       : std_logic;
        signal inputs               : t_audio_array(0 to 9);
    begin
        -- the SID sound from the socket comes in from the codec
        i2s: entity work.i2s_serializer
        port map (
            clock            => audio_clock,
            reset            => audio_reset,
            i2s_out          => AUDIO_SDO,
            i2s_in           => AUDIO_SDI,
            i2s_bclk         => AUDIO_BCLK,
            i2s_fs           => AUDIO_LRCLK,
            sample_pulse     => audio_get_sample,
            
            left_sample_out  => codec_left_in,
            right_sample_out => codec_right_in,
            left_sample_in   => codec_left_out,
            right_sample_in  => codec_right_out );

        AUDIO_MCLK <= audio_clock;

        i_sync_get: entity work.pulse_synchronizer
        port map (
            clock_in  => audio_clock,
            pulse_in  => audio_get_sample,
            clock_out => sys_clock,
            pulse_out => sys_get_sample
        );

        i_ultfilt1: entity work.sys_to_aud port map(sys_clock, sys_reset, sys_get_sample, ult_drive1, audio_clock, aud_drive1 );
        i_ultfilt2: entity work.sys_to_aud port map(sys_clock, sys_reset, sys_get_sample, ult_drive2, audio_clock, aud_drive2 );
        i_ultfilt3: entity work.sys_to_aud generic map (false) port map(sys_clock, sys_reset, sys_get_sample, ult_tape_r, audio_clock, aud_tape_r );
        i_ultfilt4: entity work.sys_to_aud generic map (false) port map(sys_clock, sys_reset, sys_get_sample, ult_tape_w, audio_clock, aud_tape_w );
        i_ultfilt5: entity work.sys_to_aud port map(sys_clock, sys_reset, sys_get_sample, ult_samp_l, audio_clock, aud_samp_l );
        i_ultfilt6: entity work.sys_to_aud port map(sys_clock, sys_reset, sys_get_sample, ult_samp_r, audio_clock, aud_samp_r );
        i_ultfilt7: entity work.sys_to_aud port map(sys_clock, sys_reset, sys_get_sample, ult_sid_1,  audio_clock, aud_sid_1 );
        i_ultfilt8: entity work.sys_to_aud port map(sys_clock, sys_reset, sys_get_sample, ult_sid_2,  audio_clock, aud_sid_2 );
        
        inputs(0) <= aud_sid_1;
        inputs(1) <= aud_sid_2;
        inputs(2) <= signed(codec_left_in(23 downto 6));
        inputs(3) <= signed(codec_right_in(23 downto 6));
        inputs(4) <= aud_samp_l;
        inputs(5) <= aud_samp_r;
        inputs(6) <= aud_drive1;
        inputs(7) <= aud_drive2;
        inputs(8) <= aud_tape_r;
        inputs(9) <= aud_tape_w;

        -- Now we have ten sources, all in audio domain, let's do some mixing
        i_mixer: entity work.generic_mixer
        generic map(
            g_num_sources => 10
        )
        port map(
            clock         => audio_clock,
            reset         => audio_reset,
            start         => audio_get_sample,
            sys_clock     => sys_clock,
            req           => io_req_mixer,
            resp          => io_resp_mixer,
            inputs        => inputs,
            out_L         => codec_left_out,
            out_R         => codec_right_out
        );

    end block;
    
    SLOT_BUFFER_EN <= buffer_en;

    i_debug_eth: entity work.eth_debug_stream
    port map (
        eth_clock     => eth_clock,
        eth_reset     => eth_reset,

        eth_u2p_data  => eth_u2p_data,
        eth_u2p_last  => eth_u2p_last,
        eth_u2p_valid => eth_u2p_valid,
        eth_u2p_ready => eth_u2p_ready,

        eth_tx_data   => eth_tx_data,
        eth_tx_last   => eth_tx_last,
        eth_tx_valid  => eth_tx_valid,
        eth_tx_ready  => eth_tx_ready,

        sys_clock     => sys_clock,
        sys_reset     => sys_reset,
        io_req        => io_req_debug,
        io_resp       => io_resp_debug,

        c64_debug_select    => c64_debug_select,
        c64_debug_data      => c64_debug_data,
        c64_debug_valid     => c64_debug_valid,
        drv_debug_data      => drv_debug_data,
        drv_debug_valid     => drv_debug_valid,
    
        IEC_ATN             => IEC_ATN_I,
        IEC_CLOCK           => IEC_CLOCK_I,
        IEC_DATA            => IEC_DATA_I
    );

    -- Transceiver
    i_rmii: entity work.rmii_transceiver
    port map (
        clock           => eth_clock,
        reset           => eth_reset,
        rmii_crs_dv     => rmii_crs_dv_d, 
        rmii_rxd        => rmii_rx_data_d,
        rmii_tx_en      => rmii_tx_en_i,
        rmii_txd        => rmii_tx_data_i,
        
        eth_rx_data     => eth_rx_data,
        eth_rx_sof      => eth_rx_sof,
        eth_rx_eof      => eth_rx_eof,
        eth_rx_valid    => eth_rx_valid,

        eth_tx_data     => eth_tx_data,
        eth_tx_eof      => eth_tx_last,
        eth_tx_valid    => eth_tx_valid,
        eth_tx_ready    => eth_tx_ready,
        ten_meg_mode    => '0'   );

    -- I/O Delays
    i_delay_rmii_rxdv: DELAYG generic map (DEL_MODE => "SCLK_ZEROHOLD") port map (A => RMII_CRS_DV,     Z => rmii_crs_dv_i);
    i_delay_rmii_rxd0: DELAYG generic map (DEL_MODE => "SCLK_ZEROHOLD") port map (A => RMII_RX_DATA(0), Z => rmii_rx_data_i(0));
    i_delay_rmii_rxd1: DELAYG generic map (DEL_MODE => "SCLK_ZEROHOLD") port map (A => RMII_RX_DATA(1), Z => rmii_rx_data_i(1));

    process(eth_clock)
    begin
        if rising_edge(eth_clock) then
            rmii_crs_dv_d  <= rmii_crs_dv_i;
            rmii_rx_data_d <= rmii_rx_data_i;
            RMII_TX_EN     <= rmii_tx_en_i;
            RMII_TX_DATA   <= rmii_tx_data_i;
        end if;
    end process;

    USB_DP      <= 'Z' when toggle='1' else '0';
    USB_DM      <= 'Z' when toggle='1' else '1';
    USB_PULLUP  <= '1';

    -- SLOT_DATA_OEn    <= '1';
    -- SLOT_DATA_DIR    <= '1';
    SLOT_ADDR_OEn    <= toggle and slot_dot_clock_f;
    SLOT_ADDR_DIR    <= RMII_RX_ER and UART_RXD and IEC_RESET_I and CAS_SENSE and CAS_MOTOR when rising_edge(CLOCK_50);
    toggle <= not toggle when rising_edge(sys_clock);
    slot_dot_clock_f <= SLOT_DOTCLK when falling_edge(sys_clock);
    flash_sck_t      <= audio_reset; -- sys_reset when falling_edge(sys_clock); -- 0 when not in reset = enabled

end architecture;
