## Json <--> YAML Conversion

Default behaviour when you're exporting KQL template files is for them to be in the Json ARM template format which is a nightmare to work with.

To make this friendlier I've written a script that runs via GitHub actions designed to convert Json <--> YAML to allow analysts to work with either format.

Along with this it links rules via their ID so if the name changes it won't generate more templates :)

(Currently in Testing.yml) - Updated to now function using an installed application and calling for a token rather than being tied to any user account. Can also get round branch protection rules.
