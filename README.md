# Decentralized Product Warranty Tracker

A Clarity smart contract for managing product warranties as transferable NFTs on the Stacks blockchain.

## Overview

This contract enables manufacturers to:
- Register products with warranty details
- Issue NFT-based warranties to customers
- Manage warranty terms, duration, and transferability

Product owners can:
- Transfer their warranty to another user (if the warranty is transferable)
- Verify warranty validity and details

## Features

- **NFT-Based Warranties**: Each warranty is a non-fungible token
- **Transferable Ownership**: Warranties can be transferred between users
- **Warranty History**: Complete ownership history is maintained
- **Manufacturer Controls**: Manufacturers can void, extend, or update warranty terms
- **Product Tracking**: Products and their warranties are tracked by ID

## Contract Functions

### Read-Only Functions

- `get-last-warranty-id`: Returns the latest warranty ID
- `get-warranty-details`: Get details for a specific warranty
- `get-product-warranties`: Get all warranties for a product
- `get-manufacturer-products`: Get all products registered by a manufacturer
- `get-warranty-history`: Get the ownership history of a warranty
- `is-warranty-active`: Check if a warranty is active and not expired
- `get-warranty-owner`: Get the current owner of a warranty

### Public Functions

- `register-product`: Register a new product with warranty
- `transfer-warranty`: Transfer a warranty to another user
- `void-warranty`: Void a warranty (manufacturer only)
- `extend-warranty`: Extend warranty duration (manufacturer only)
- `update-warranty-terms`: Update warranty terms (manufacturer only)
- `make-warranty-transferable`: Make a non-transferable warranty transferable (manufacturer only)

## Usage Examples

### Registering a Product with Warranty

```clarity
(contract-call? .product-tracker register-product 
  "PROD-123" 
  "Smartphone X" 
  "SN12345678" 
  u52560 
  "Standard 1-year warranty covering manufacturing defects" 
  true)
```

### Transferring a Warranty

```clarity
(contract-call? .product-tracker transfer-warranty u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Extending a Warranty

```clarity
(contract-call? .product-tracker extend-warranty u1 u26280)
```

## Error Codes

- `u1`: Warranty ID already exists
- `u2`: Warranty not found
- `u3`: Warranty owner not found
- `u4`: Not the warranty owner
- `u5`: Warranty is not transferable
- `u6`: Warranty is not active
- `u7`: Warranty has expired
- `u8`: Not the manufacturer
- `u9`: Warranty is already transferable