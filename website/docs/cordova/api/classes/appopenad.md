---
id: "appopenad"
title: "Class: AppOpenAd"
sidebar_label: "AppOpenAd"
sidebar_position: 0
custom_edit_url: null
---

# Class: AppOpenAd

## Hierarchy

- *GenericAd*

  ↳ **AppOpenAd**

## Constructors

### constructor

\+ **new AppOpenAd**(`opts`: [*MobileAdOptions*](../index.md#mobileadoptions)): [*AppOpenAd*](appopenad.md)

#### Parameters

| Name | Type |
| :------ | :------ |
| `opts` | [*MobileAdOptions*](../index.md#mobileadoptions) |

**Returns:** [*AppOpenAd*](appopenad.md)

Overrides: GenericAd.constructor

Defined in: app-open.ts:36

## Properties

### id

• `Readonly` **id**: *number*

Inherited from: GenericAd.id

Defined in: api.ts:11

___

### opts

• `Protected` `Readonly` **opts**: [*MobileAdOptions*](../index.md#mobileadoptions)

Inherited from: GenericAd.opts

Defined in: api.ts:13

## Accessors

### adUnitId

• get **adUnitId**(): *string*

**Returns:** *string*

Defined in: api.ts:31

## Methods

### isLoaded

▸ **isLoaded**(): *Promise*<boolean\>

**Returns:** *Promise*<boolean\>

Inherited from: GenericAd.isLoaded

Defined in: app-open.ts:16

___

### load

▸ **load**(): *Promise*<void\>

**Returns:** *Promise*<void\>

Inherited from: GenericAd.load

Defined in: app-open.ts:23

___

### show

▸ **show**(): *Promise*<boolean\>

**Returns:** *Promise*<boolean\>

Inherited from: GenericAd.show

Defined in: app-open.ts:28

___

### getAdById

▸ `Static` **getAdById**(`id`: *number*): [*MobileAd*](mobilead.md)<[*MobileAdOptions*](../index.md#mobileadoptions)\>

#### Parameters

| Name | Type |
| :------ | :------ |
| `id` | *number* |

**Returns:** [*MobileAd*](mobilead.md)<[*MobileAdOptions*](../index.md#mobileadoptions)\>

Inherited from: GenericAd.getAdById

Defined in: api.ts:22