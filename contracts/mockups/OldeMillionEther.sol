/*
MillionEther smart contract - decentralized advertising platform.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.2;

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";

contract OldeMillionEther is Destructible {

    struct Block {
        address landlord;
        uint imageID;
        uint sellPrice;
    }
    Block[101][101] private blocks; 

    constructor() public {
        blocks[59][59].landlord = 0xCA9f7D9aD4127e374cdaB4bd0a884790C1B03946;
        blocks[59][60].landlord = 0x26bFdbfF9008693398fB8854db0d953aF4aF3e55;
        blocks[60][60].landlord = 0x95fdB8BB2167d7DA27965952CD4c15dA6Ac46d60;
    }

    function getBlockInfo(uint8 x, uint8 y) 
        public constant returns (address landlord, uint imageID, uint sellPrice) 
    {
        return (blocks[x][y].landlord, blocks[x][y].imageID, blocks[x][y].sellPrice);
    }

    // function set_current_state() public {
    //     .....
    //     blocks[19][19].landlord = 0xCA9f7D9aD4127e374cdaB4bd0a884790C1B03946;
    //     blocks[46][7].landlord = 0x26bFdbfF9008693398fB8854db0d953aF4aF3e55;
    //     ....
    // }

}