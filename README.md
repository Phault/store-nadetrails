store-nadetrails
============

### Description
Store module that allows players to buy custom trails for their grenades in the store.

The plugin is based upon the code of alongubkin's store-trails module.

### Requirements

* [Store](https://forums.alliedmods.net/showthread.php?t=207157)
* [SDKHooks](http://forums.alliedmods.net/showthread.php?t=106748) 
* [SMJansson](https://forums.alliedmods.net/showthread.php?t=184604)

### Features

* **Customizable** - You can have any amount of trails you want, and you can customize each trail in its `attrs` field.
* **CS:GO Trails support** - This plugin works in CS:GO, even though the game doesn't support the `env_spritetrail` entity.
* **Materials are downloaded automatically** - You don't need to configure that.

### Installation

Download the `store-nadetrails.zip` archive from the plugin thread and extract to your `sourcemod` folder intact. Then open your store web panel, navigate to Import/Export System under the Tools menu, and import configs/store/json-import/nadetrails.json.

### Adding More Trails

You can use the web panel to add nadetrails. Open the web panel, navigate to Add New Item under the Items menu. In type and loadout_slot, type nadetrails. Change name, display_name, description and attrs to customize the new trail. 

The attrs field should look like:

    {
        "material": "materials/sprites/store/trails/8bitmushroom.vmt",
        "lifetime": 1,
        "width": 3,
        "endwidth": 1,
        "fadelength": 1,
        "color": [255, 255, 255, 255]
    }

These are the default values and you can leave any of them out (except material).