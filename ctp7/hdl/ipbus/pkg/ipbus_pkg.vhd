library IEEE;
use IEEE.STD_LOGIC_1164.all;

package ipbus_bridge_pkg is

  type t_axi_ipb_state is (IDLE, WRITE, READ, WAIT_FOR_WRITE_ACK, WAIT_FOR_READ_ACK, AXI_READ_HANDSHAKE, AXI_WRITE_HANDSHAKE);

end ipbus_bridge_pkg;
