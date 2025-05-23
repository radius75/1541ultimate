--------------------------------------------------------------------------------
-- Gideon's Logic Architectures - Copyright 2014
-- Entity: bus_converter
-- Date:2015-02-28  
-- Author: Gideon     
-- Description: This module takes the Wishbone alike memory bus and splits it
--              into a 32 bit DRAM bus and an 8-bit IO bus
--
-- This module is based on "dmem_splitter" from the mblite era. However,
-- this uses the rvlite definitions and is little endian.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
    use work.mem_bus_pkg.all;
    use work.io_bus_pkg.all;
    use work.core_pkg.all;

entity bus_converter is
    generic (
        g_tag           : std_logic_vector(7 downto 0) := X"AE";
        g_bootrom       : boolean := false;
        g_bootaddr      : std_logic_vector(31 downto 16) := X"8000";
        g_io_bit        : natural := 26;
        g_support_io    : boolean := true );
	port  (
        clock       : in  std_logic;
        reset       : in  std_logic;
        
        dmem_req    : in  t_dmem_req;
        dmem_resp   : out t_dmem_resp;
        
        mem_req     : out t_mem_req_32;
        mem_resp    : in  t_mem_resp_32;
        
        bram_req    : out t_bram_req;
        bram_resp   : in  t_bram_resp;

        io_busy     : out std_logic;
        io_req      : out t_io_req;
        io_resp     : in  t_io_resp );

end entity;

architecture arch of bus_converter is
    type t_state is (idle, mem_read, mem_write, io_access, boot_read);
    signal state        : t_state;

    signal mem_req_i   : t_mem_req_32 := c_mem_req_32_init;
    signal io_req_i    : t_io_req := c_io_req_init;
    signal addr_i      : unsigned(mem_req_i.address'range);
    type t_int4_array is array(natural range <>) of integer range 0 to 3;
    --                                               0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F  => 1,2,4,8 byte, 3,C word, F dword
    constant c_remain   : t_int4_array(0 to 15) := ( 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 3 );
    signal remain       : integer range 0 to 3;
begin
    process(state, mem_resp)
    begin
        dmem_resp.ena_i <= '0';
        case state is
        when idle =>
            dmem_resp.ena_i <= '1';
        when mem_read | io_access =>
            dmem_resp.ena_i <= '0';
        when others =>
            dmem_resp.ena_i <= '0';
        end case;
    end process;

    process(io_req_i, mem_req_i, addr_i)
    begin
        io_req <= io_req_i;
        io_req.address <= addr_i(io_req.address'range);
        mem_req <= mem_req_i;
        mem_req_i.address <= addr_i;
        mem_req_i.address(1 downto 0) <= "00";

        -- Fill in the byte to write, based on the address
        -- Note that mem-req stored the 32 bits data, so we can use it, dmem.o might have become invalid
        case addr_i(1 downto 0) is
        when "11" =>
            io_req.data <= mem_req_i.data(31 downto 24);
        when "10" =>
            io_req.data <= mem_req_i.data(23 downto 16);
        when "01" =>
            io_req.data <= mem_req_i.data(15 downto 08);
        when "00" =>
            io_req.data <= mem_req_i.data(07 downto 00);
        when others =>
            null;
        end case; 
    end process;

    bram_req.ena        <= '1' when dmem_req.ena_o = '1' and dmem_req.adr_o(31 downto 16) = g_bootaddr else '0';
    bram_req.wen        <= dmem_req.we_o;
    bram_req.address    <= unsigned(dmem_req.adr_o(bram_req.address'range));
    bram_req.data       <= dmem_req.dat_o;

    process(clock)
    begin
        if rising_edge(clock) then
            io_req_i.read <= '0';
            io_req_i.write <= '0';
            
            case state is
            when idle =>
                if dmem_req.ena_o = '1' then
                    dmem_resp.dat_i <= (others => '0');
                    addr_i <= unsigned(dmem_req.adr_o(mem_req_i.address'range));
                    mem_req_i.byte_en <= dmem_req.sel_o;
                    mem_req_i.data <= dmem_req.dat_o;
                    mem_req_i.read_writen <= not dmem_req.we_o;
                    mem_req_i.tag <= g_tag;
                    remain <= c_remain(to_integer(unsigned(dmem_req.sel_o)));
                    
                    if dmem_req.adr_o(31 downto 16) = g_bootaddr and g_bootrom then
                        -- writes are immediate
                        if dmem_req.we_o = '0' then
                            state <= boot_read;
                        end if;
                    elsif dmem_req.adr_o(g_io_bit) = '0' or not g_support_io then
                        mem_req_i.request <= '1';
                        if dmem_req.we_o = '1' then
                            state <= mem_write;
                        else
                            state <= mem_read;
                        end if;
                    else -- I/O
                        if dmem_req.we_o = '1' then
                            io_req_i.write <= '1';
                        else
                            io_req_i.read <= '1';
                        end if;
                        state <= io_access;
                    end if;
                end if;

            when mem_read =>
                if mem_resp.rack_tag = g_tag and mem_resp.rack = '1' then
                    mem_req_i.request <= '0';
                end if;
                if mem_resp.dack_tag = g_tag then
                    dmem_resp.dat_i <= mem_resp.data;
                    state <= idle;
                end if;
                
            when mem_write =>
                if mem_resp.rack_tag = g_tag and mem_resp.rack = '1' then
                    mem_req_i.request <= '0';
                    state <= idle;
                end if;

            when boot_read =>
                dmem_resp.dat_i <= bram_resp.data;
                state <= idle;
                
            when io_access =>
                case addr_i(1 downto 0) is
                when "11" =>
                    dmem_resp.dat_i(31 downto 24) <= io_resp.data;
                when "10" =>
                    dmem_resp.dat_i(23 downto 16) <= io_resp.data;
                when "01" =>
                    dmem_resp.dat_i(15 downto 8) <= io_resp.data;
                when "00" =>
                    dmem_resp.dat_i(7 downto 0) <= io_resp.data;
                when others =>
                    null;
                end case;

                if io_resp.ack = '1' then
                    if remain = 0 then
                        state <= idle;
                    else
                        remain <= remain - 1;
                        addr_i(1 downto 0) <= addr_i(1 downto 0) + 1;
                        if mem_req_i.read_writen = '0' then
                            io_req_i.write <= '1';
                        else
                            io_req_i.read <= '1';
                        end if;
                    end if;
                end if;

            when others =>
                null;
            end case;

            if reset='1' then
                state <= idle;
                mem_req_i.request <= '0';
            end if;
        end if;
    end process;
    io_busy <= '1' when state = io_access else '0';
    
end architecture;
