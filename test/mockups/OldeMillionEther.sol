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

contract OldeMillionEther {

    struct Block {
        address landlord;
        uint imageID;
        uint sellPrice;
    }
    Block[101][101] private blocks; 

    constructor() public {
        blocks[19][19].landlord = 0xCA9f7D9aD4127e374cdaB4bd0a884790C1B03946;
        blocks[46][7].landlord = 0x26bFdbfF9008693398fB8854db0d953aF4aF3e55;
        //blocks[1][1].landlord = 0x95fdB8BB2167d7DA27965952CD4c15dA6Ac46d60;
        blocks[2][1].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[2][2].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[3][1].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[3][2].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[49][19].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[49][20].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[49][21].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[50][19].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[50][20].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[50][21].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[51][19].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[51][20].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[51][21].landlord = 0xFBFE8eE0bE2a31774eA1913d49f2Ba77FefC7792;
        blocks[65][20].landlord = 0x00b3D1a0F7eC70e3F29086A92da6010a98F90e53;
        blocks[49][49].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[49][50].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[49][51].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[50][49].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[50][50].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[50][51].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[51][49].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[51][50].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[51][51].landlord = 0xA2Bc058e2076829AD6b5D44dd89F738dBfb1cF05;
        blocks[49][29].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[49][30].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[50][29].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[50][30].landlord = 0x003E5d6ddcf2Ce510c935bded1d666D3e601dAdF;
        blocks[24][55].landlord = 0xb70a6e9c93Fa69D96aB2712C48Ac0669Eb6bB2BB;
        blocks[24][56].landlord = 0xb70a6e9c93Fa69D96aB2712C48Ac0669Eb6bB2BB;
        blocks[25][55].landlord = 0xb70a6e9c93Fa69D96aB2712C48Ac0669Eb6bB2BB;
        blocks[25][56].landlord = 0xb70a6e9c93Fa69D96aB2712C48Ac0669Eb6bB2BB;
        blocks[49][69].landlord = 0x70b2b3f1912777e3eeA440061377a175c1F7ECc3;
        blocks[49][70].landlord = 0x70b2b3f1912777e3eeA440061377a175c1F7ECc3;
        blocks[50][69].landlord = 0x70b2b3f1912777e3eeA440061377a175c1F7ECc3;
        blocks[50][70].landlord = 0x70b2b3f1912777e3eeA440061377a175c1F7ECc3;
        blocks[50][41].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[50][42].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[51][42].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[51][41].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[52][41].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[52][42].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[51][43].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[52][43].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[50][43].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[50][44].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[51][44].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[52][44].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[53][44].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[50][45].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[51][45].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[52][45].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[53][45].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[53][41].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[53][42].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[53][43].landlord = 0x9AF5Ba5a5566bA95AFC13E790d80440f407aa1a8;
        blocks[50][46].landlord = 0x56a985D770fF9d5B98b2078aA869499696808E1A;
        blocks[50][47].landlord = 0x56a985D770fF9d5B98b2078aA869499696808E1A;
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