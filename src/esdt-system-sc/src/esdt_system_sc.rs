#![no_std]

multiversx_sc::imports!();

const ZERO_ASCII: u8 = b'0';
const DASH: u8 = b'-';
const RAND_CHARS_LEN: usize = 6;

type ESDTDataV2 struct {
	OwnerAddress             []byte        `protobuf:"bytes,1,opt,name=OwnerAddress,proto3" json:"OwnerAddress"`
	TokenName                []byte        `protobuf:"bytes,2,opt,name=TokenName,proto3" json:"TokenName"`
	TickerName               []byte        `protobuf:"bytes,3,opt,name=TickerName,proto3" json:"TickerName"`
	TokenType                []byte        `protobuf:"bytes,4,opt,name=TokenType,proto3" json:"TokenType"`
	Mintable                 bool          `protobuf:"varint,5,opt,name=Mintable,proto3" json:"Mintable"`
	Burnable                 bool          `protobuf:"varint,6,opt,name=Burnable,proto3" json:"Burnable"`
	CanPause                 bool          `protobuf:"varint,7,opt,name=CanPause,proto3" json:"CanPause"`
	CanFreeze                bool          `protobuf:"varint,8,opt,name=CanFreeze,proto3" json:"CanFreeze"`
	CanWipe                  bool          `protobuf:"varint,9,opt,name=CanWipe,proto3" json:"CanWipe"`
	Upgradable               bool          `protobuf:"varint,10,opt,name=Upgradable,proto3" json:"CanUpgrade"`
	CanChangeOwner           bool          `protobuf:"varint,11,opt,name=CanChangeOwner,proto3" json:"CanChangeOwner"`
	IsPaused                 bool          `protobuf:"varint,12,opt,name=IsPaused,proto3" json:"IsPaused"`
	MintedValue              *math_big.Int `protobuf:"bytes,13,opt,name=MintedValue,proto3,casttypewith=math/big.Int;github.com/multiversx/mx-chain-core-go/data.BigIntCaster" json:"MintedValue"`
	BurntValue               *math_big.Int `protobuf:"bytes,14,opt,name=BurntValue,proto3,casttypewith=math/big.Int;github.com/multiversx/mx-chain-core-go/data.BigIntCaster" json:"BurntValue"`
	NumDecimals              uint32        `protobuf:"varint,15,opt,name=NumDecimals,proto3" json:"NumDecimals"`
	CanAddSpecialRoles       bool          `protobuf:"varint,16,opt,name=CanAddSpecialRoles,proto3" json:"CanAddSpecialRoles"`
	NFTCreateStopped         bool          `protobuf:"varint,17,opt,name=NFTCreateStopped,proto3" json:"NFTCreateStopped"`
	CanTransferNFTCreateRole bool          `protobuf:"varint,18,opt,name=CanTransferNFTCreateRole,proto3" json:"CanTransferNFTCreateRole"`
	SpecialRoles             []*ESDTRoles  `protobuf:"bytes,19,rep,name=SpecialRoles,proto3" json:"SpecialRoles"`
	NumWiped                 uint32        `protobuf:"varint,20,opt,name=NumWiped,proto3" json:"NumWiped"`
	CanCreateMultiShard      bool          `protobuf:"varint,21,opt,name=CanCreateMultiShard,proto3" json:"CanCreateMultiShard"`
}

pub enum TokenType {
    Fungible,
    NonFungible,
    SemiFungible
}
pub struct ESDTData<M: ManagedTypeApi> {
    pub owner_address: ManagedAddress<M>,
    pub token_name: ManagedBuffer<M>,
    pub ticker_name: ManagedBuffer<M>,
    pub token_type: EsdtTokenData<>
    TokenType                []byte        `protobuf:"bytes,4,opt,name=TokenType,proto3" json:"TokenType"`
	Mintable                 bool          `protobuf:"varint,5,opt,name=Mintable,proto3" json:"Mintable"`
	Burnable                 bool          `protobuf:"varint,6,opt,name=Burnable,proto3" json:"Burnable"`
	CanPause                 bool          `protobuf:"varint,7,opt,name=CanPause,proto3" json:"CanPause"`
	CanFreeze                bool          `protobuf:"varint,8,opt,name=CanFreeze,proto3" json:"CanFreeze"`
	CanWipe                  bool          `protobuf:"varint,9,opt,name=CanWipe,proto3" json:"CanWipe"`
	Upgradable               bool          `protobuf:"varint,10,opt,name=Upgradable,proto3" json:"CanUpgrade"`
	CanChangeOwner           bool          `protobuf:"varint,11,opt,name=CanChangeOwner,proto3" json:"CanChangeOwner"`
	IsPaused                 bool          `protobuf:"varint,12,opt,name=IsPaused,proto3" json:"IsPaused"`
	MintedValue              *math_big.Int `protobuf:"bytes,13,opt,name=MintedValue,proto3,casttypewith=math/big.Int;github.com/multiversx/mx-chain-core-go/data.BigIntCaster" json:"MintedValue"`
	BurntValue               *math_big.Int `protobuf:"bytes,14,opt,name=BurntValue,proto3,casttypewith=math/big.Int;github.com/multiversx/mx-chain-core-go/data.BigIntCaster" json:"BurntValue"`
	NumDecimals              uint32        `protobuf:"varint,15,opt,name=NumDecimals,proto3" json:"NumDecimals"`
	CanAddSpecialRoles       bool          `protobuf:"varint,16,opt,name=CanAddSpecialRoles,proto3" json:"CanAddSpecialRoles"`
	NFTCreateStopped         bool          `protobuf:"varint,17,opt,name=NFTCreateStopped,proto3" json:"NFTCreateStopped"`
	CanTransferNFTCreateRole bool          `protobuf:"varint,18,opt,name=CanTransferNFTCreateRole,proto3" json:"CanTransferNFTCreateRole"`
	SpecialRoles             []*ESDTRoles  `protobuf:"bytes,19,rep,name=SpecialRoles,proto3" json:"SpecialRoles"`
	NumWiped                 uint32        `protobuf:"varint,20,opt,name=NumWiped,proto3" json:"NumWiped"`
	CanCreateMultiShard      bool          `protobuf:"varint,21,opt,name=CanCreateMultiShard,proto3" json:"CanCreateMultiShard"`
}


#[multiversx_sc::contract]
pub trait PayableFeatures {
    #[init]
    fn init(&self) {}

    #[payable("EGLD")]
    #[endpoint(issue)]
    fn issue_fungible(
        &self,
        _token_display_name: ManagedBuffer,
        token_ticker: ManagedBuffer,
        initial_supply: BigUint,
        _num_decimals: usize,
        _token_properties: MultiValueEncoded<MultiValue2<ManagedBuffer, bool>>,
    ) -> TokenIdentifier {
        let new_token_id = self.create_new_token_id(token_ticker);
        require!(new_token_id.is_valid_esdt_identifier(), "Invalid token ID");

        if initial_supply > 0 {
            let caller = self.blockchain().get_caller();

            self.send()
                .esdt_local_mint(&new_token_id, 0, &initial_supply);
            self.send()
                .direct_esdt(&caller, &new_token_id, 0, &initial_supply);
        }

        new_token_id
    }

    #[payable("EGLD")]
    #[endpoint(issueNonFungible)]
    fn issue_non_fungible(
        &self,
        _token_display_name: ManagedBuffer,
        token_ticker: ManagedBuffer,
        _token_properties: MultiValueEncoded<MultiValue2<ManagedBuffer, bool>>,
    ) -> TokenIdentifier {
        self.create_new_token_id(token_ticker)
    }

    #[payable("EGLD")]
    #[endpoint(issueSemiFungible)]
    fn issue_semi_fungible(
        &self,
        _token_display_name: ManagedBuffer,
        token_ticker: ManagedBuffer,
        _token_properties: MultiValueEncoded<MultiValue2<ManagedBuffer, bool>>,
    ) -> TokenIdentifier {
        self.create_new_token_id(token_ticker)
    }

    #[payable("EGLD")]
    #[endpoint(registerMetaESDT)]
    fn issue_meta_esdt(
        &self,
        _token_display_name: ManagedBuffer,
        token_ticker: ManagedBuffer,
        _num_decimals: usize,
        _token_properties: MultiValueEncoded<MultiValue2<ManagedBuffer, bool>>,
    ) -> TokenIdentifier {
        self.create_new_token_id(token_ticker)
    }

    #[endpoint(setSpecialRole)]
    fn set_special_roles(
        &self,
        _token_id: TokenIdentifier,
        _address: ManagedAddress,
        _roles: MultiValueEncoded<EsdtLocalRole>,
    ) {
    }

    #[payable("EGLD")]
    #[endpoint(registerAndSetAllRoles)]
    fn register_and_set_all_roles(
        &self,
        _token_display_name: ManagedBuffer,
        token_ticker: ManagedBuffer,
        _token_type_name: ManagedBuffer,
        _num_decimals: usize,
    ) -> TokenIdentifier {
        self.create_new_token_id(token_ticker)
    }

    fn create_new_token_id(&self, token_ticker: ManagedBuffer) -> TokenIdentifier {
        let nr_issued_tokens = self.nr_issued_tokens().get();
        let mut rand_chars = [ZERO_ASCII; RAND_CHARS_LEN];
        for c in &mut rand_chars {
            *c += nr_issued_tokens;
        }

        self.nr_issued_tokens().update(|nr| *nr += 1);

        let mut token_id = token_ticker;
        token_id.append_bytes(&[DASH][..]);
        token_id.append_bytes(&rand_chars);

        token_id.into()
    }

    #[storage_mapper("nrIssuedTokens")]
    fn nr_issued_tokens(&self) -> SingleValueMapper<u8>;
}
