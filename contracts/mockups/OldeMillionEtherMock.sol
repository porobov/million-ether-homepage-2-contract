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

contract OldeMillionEtherMock is Destructible {

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
        blocks[60][61].landlord = 0x1000000000000000000000000000000000000001;
        blocks[60][62].landlord = 0x2000000000000000000000000000000000000002;
        blocks[60][63].landlord = 0x3000000000000000000000000000000000000003;
        blocks[60][64].landlord = 0x4000000000000000000000000000000000000004;
        blocks[60][65].landlord = 0x5000000000000000000000000000000000000000;
        blocks[60][66].landlord = 0x6000000000000000000000000000000000000000;
        blocks[60][67].landlord = 0x7000000000000000000000000000000000000000;
        blocks[60][68].landlord = 0x8000000000000000000000000000000000000000;
        blocks[60][69].landlord = 0x9000000000000000000000000000000000000000;
        blocks[60][70].landlord = 0x1000000000000000000000000000000000000000;
        blocks[60][71].landlord = 0x1100000000000000000000000000000000000000;
        blocks[60][72].landlord = 0x1200000000000000000000000000000000000000;
        blocks[60][73].landlord = 0x1300000000000000000000000000000000000000;
        blocks[60][74].landlord = 0x1400000000000000000000000000000000000000;
        blocks[60][75].landlord = 0x1500000000000000000000000000000000000000;
        blocks[60][76].landlord = 0x1600000000000000000000000000000000000000;
        blocks[60][77].landlord = 0x1700000000000000000000000000000000000000;
        blocks[60][78].landlord = 0x1800000000000000000000000000000000000000;
        blocks[60][79].landlord = 0x1900000000000000000000000000000000000000;
        blocks[60][80].landlord = 0x2000000000000000000000000000000000000000;
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