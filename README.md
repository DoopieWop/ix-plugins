# Plugins, their functions and installation

## Persistence: Retro Edition
Disregarding the cheesy name, this plugin replaces Helix's persistence plugin with GMod's persistence system. Why? GMod's system uses the duplicator's saving and loading functions, as such entity information that Helix doesn't support isn't lost and certain entities like vehicles can be saved. Even constraints (ropes, welds) can be saved.

### GMod's persistence system was replaced by Helix's system early on, due to reported lag. I don't know if this is still the case in 2023, so use at your own risk!

### While GMod's persistence system can save more complex entity configuration, this also results in a large save file. 3 entities on the persistence plugin takes around 1KB, with GMod's system its 4KB.

This plugin also includes a transfer command, to transfer saved props from Helix's persistence plugin to GMod's persistence system. Simply enter "ix_persistenceTransfer" into the server console and follow the prompts. **In order for this to work correctly, there mustn't be any props loaded from the old persistent system. Ensure the original persistence plugin is unloaded and none of its props are on the map, while executing this command!** You should only run the transfer command once.

Upon installation into your schema plugins folder, this plugin will disable the original persistence plugin. **Ensure that the plugin is fully unloaded**, by restarting the server on first install.
