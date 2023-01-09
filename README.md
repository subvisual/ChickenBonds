# Chicken Bonds
Chicken bonds go to starknet

##  Proof of concept 

Chicken Bonds are a new mechanism in liquidity acquisition, introduced by Liquity team, *"to bootstrap protocol owned liquidity (POL) at no cost while boosting yield opportunities for their end users"* **[1, p1]**

Our purpose is to take some key concepts from this mechanism and adapt it to a portfolio allocation strategy, similar to a collateralized fund obligation (CFO). **[2]** The main purpose of a CFO is to provide liquidity for limited partnership interests of private equity funds. In our adaptation of this, the purpose is to provide liquidity to the stake in certain cryptocurrencies and crypto-instruments without touching the underlying assets.

The main point is to allocate the funds from the bonders into several different tranches based on priority. The first tranche would be the principal. The second tranche would be the yield resulting from the allocation of the principal in yield-bearing opportunities. The third and final tranche would correspond to the redemption at maturity. These will all correspond to different user interactions that are possible within this context of chicken bond.

Unlike their original counterparts in the non-crypto world, chicken bonds as securitised equity would be transparent to the end-user and their risk analysis.

## Deploys
* bond : `0x027be115b67461fe8921a4766cbdf5260346b4db59bc5ab8e2037f86c2b52c7a`

* lusd : `0x03bea63324fa4c2ad9c02c4d1a0db2a8ea3929da98be364f28862aacb3ddaa34`

* blusd : `0x01e816cf8181eda780d19ef8e43c93b8911e400fcd7b13849185f23c52b2164b`

* mock curve pool : `0x02c5baed6c513527285adebccd102cbf4df879defd381188698fb4b3d42b16b0`

* mock yearn lusd vault : `0x033a603e39c7f38d2a73cee5b12a214051f8e383b2debedf8ca83a5cba0e2c41`

* mock yearn curve vault : `0x106d557d8bb8e4214958193a4b79140737538a2a3b6a15b936c829a0847b37c`

* chicken bond manager : `0x05e219d051675228a38c7485f2d75754a457ee77d48e014e37973d8e2faa688e`

## Original paper and implementation

* [Original paper](https://github.com/liquity/ChickenBond/blob/main/papers/ChickenBonds%20Whitepaper.pdf)
* [Original implementation](https://github.com/liquity/ChickenBond)
