# yggdrai
Homunculus/Mercenary AI for Ragnarok Online

A rewrite of LunaAI, my previous Homun/Merc AI project. Now with less pollution of the global environment.

A: How to install?
Q: Copy/Uncompress the USER_AI/ under your AI/ folder in your RO directory.

A: How to use?
Q: Modify AI.lua/AI_M.lua to suit your needs. Just call the function returned from yggdrai.lua with a profile path and your Homunculus/Mercenary's GID as parameters.

A: How to configure?
Q: Program your own profile. You can use 'profiles/sample.lua' as a basic structure to your code. You must have to return a function that receives an Actor table that describes your Homunculus/Mercenary and extra parameters from the call of the yggdrai function in your AI.lua/AI_M.lua, and returns a state transition table, a command handler, an initial state and arguments for this state.

I might update this repository with some useful AI profiles and some utility functions. Please, take a look in my LunaAI project and in my AI-Tricks project, if you need any inspiration.

YggdrAI: https://github.com/ediiknorand/yggdrai
LunaAI: https://github.com/ediiknorand/lunaai
AI-Tricks: https://github.com/ediiknorand/ai-tricks
