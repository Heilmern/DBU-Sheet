/// basic_items.dart
/// ---------------------------------------------------------------------------
/// Static rules data for BASIC ITEMS (Inventory page → Basic Items). Single
/// source of truth for the site's Basic Items and Special Basic Items — the
/// consumables and utility gadgets a character carries (Capsules, Senzu Beans,
/// Bombs, Medicine, Scouters' handheld cousin the Scout Scope, etc.).
///
/// Unlike Apparel/Weapons/Accessories, Basic Items are almost entirely
/// Action-TRIGGERED (throw / consume / activate) rather than passively "worn" —
/// none grant an unconditional while-possessed stat bonus — so this is a
/// REFERENCE CATALOGUE (like the Conditions/States trackers), NOT an automated
/// sub-system. The player owns items, tracks a Quantity, and reads the effect;
/// nothing here feeds the derived stats (there is no calculator hook).
///
/// [kDbuBasicItems] holds both the standard Basic Items (each with a Craft DC
/// Difficulty Category and any [Tech]/[Med]/[Food] tags) and the Special Basic
/// Items ([BasicItemDef.isSpecial] — ARC-granted, "cannot be obtained by
/// Crafting", so no Craft DC).
///
/// PROVENANCE: transcribed from the offline ZIM archive's
/// `/basic-items-accessories/` article (dbu-rpg.com, 2026-07-03 backup),
/// cross-checked against the live page — see the `zim-archive-lookup` note.
/// ---------------------------------------------------------------------------
library;

/// One entry in the Basic Items catalogue.
class BasicItemDef {
  const BasicItemDef({
    required this.name,
    required this.craftDc,
    required this.description,
    required this.effects,
    this.tags = const [],
    this.isSpecial = false,
  });

  final String name;

  /// The Craft DC Difficulty Category (e.g. "Apprentice", "Master"). '' for
  /// Special Basic Items, which cannot be Crafted.
  final String craftDc;

  /// The item's short flavour sentence (the line before "–Craft DC:").
  final String description;

  /// The verbatim Effects text.
  final String effects;

  /// Any tags after the name: 'Tech' (Technology), 'Med' (Medicine, made with a
  /// Medicine Skill Check) and/or 'Food' (made with a Cooking Skill Check).
  final List<String> tags;

  /// Special Basic Items are ARC-granted (no Craft DC).
  final bool isSpecial;

  bool get isTech => tags.contains('Tech');

  /// The tags formatted as the site shows them, e.g. "[Tech]" or "[Med]".
  String get tagLabel => tags.map((t) => '[$t]').join(' ');
}

/// The full Basic Items catalogue (standard first, then Special). Effects text
/// transcribed verbatim from the site.
const List<BasicItemDef> kDbuBasicItems = [
  // --- Basic Items ----------------------------------------------------------
  BasicItemDef(
    name: 'Animorphaline (Bad Batch)',
    craftDc: 'Master',
    tags: ['Med'],
    description: 'An experimental drug that turns you permanently into an '
        'anthropomorphic animal.',
    effects:
        'Spend an Action to consume this Basic Item and, if you meet the Racial '
        'Requirement, permanently gain the Beast-Man Factor. You must select the '
        'Part-Beast Factor Trait, replacing a Secondary Racial Trait of your choice.',
  ),
  BasicItemDef(
    name: 'Animorphaline (Perfect)',
    craftDc: 'Grandmaster',
    tags: ['Med'],
    description: 'A refined medicine that temporarily gives you animal features.',
    effects:
        'Spend an Action to consume this Basic Item and, if you meet the Racial '
        'Requirement, gain the Beast-Man Factor until the end of the Combat '
        'Encounter. You must select the Part-Beast Factor Trait, replacing a '
        'Secondary Racial Trait of your choice for the remainder of the Combat '
        'Encounter (you regain that Secondary Racial Trait afterwards).',
  ),
  BasicItemDef(
    name: 'Bomb',
    craftDc: 'Qualified',
    tags: ['Tech'],
    description: 'An explosive device that you place in a specific location.',
    effects:
        'When you create this Basic Item, record your Scholarship Modifier. '
        'Then, select a trigger:\n\nRemote Controlled. You can trigger this Bomb '
        'using a Remote Control Basic Item.\n\nTimed. When you place this Bomb, '
        'you can select any number of Combat Rounds. This Bomb will trigger once '
        'that number of Combat Rounds have passed.\n\nProximity. After you have '
        'placed this Bomb, if any Character except the Character that placed this '
        'Bomb moves on a Square within a Sphere AoE (centered on the Bomb), the '
        'Bomb is triggered.\n\nA Bomb can be placed on any Square, Feature, or '
        'unoccupied Vehicle/Battle jacket by spending 1 Action while adjacent to '
        'your chosen position to place the bomb.\n\nOnce a Bomb is triggered, it '
        'uses the Basic Attack Maneuver of the Clearing (Energy) Profile as an '
        'Out-of-Sequence Maneuver, using the recorded Scholarship Modifier as '
        "its Damage Attribute for this Attacking Maneuver. A Bomb's Strike Roll "
        'for this Attacking Maneuver will automatically succeed.',
  ),
  BasicItemDef(
    name: 'Caltrops',
    craftDc: 'Qualified',
    description: 'A handful of spikes you scatter across the ground to prevent '
        'pursuit.',
    effects:
        'Select a Square within a Destructive Sphere AoE (centered on you). '
        'Create a Sphere AoE centered on that Square. Any Character (except '
        'those in a High Environment) who moves through any Square in that AoE '
        'has their Life Points reduced by 1d4(bT). This effect does not stack if '
        'they move through multiple Squares.',
  ),
  BasicItemDef(
    name: 'Capsule',
    craftDc: 'Qualified',
    tags: ['Tech'],
    description: 'An item that can hold almost anything in it, keeping it in a '
        'compact, easy to carry device.',
    effects:
        'You can store any Basic Item into a Capsule. Vehicles and Bases can '
        'also be stored within Capsules through the Capsule Quality. You cannot '
        'store a living thing or a Capsule within a Capsule.\n\nYou can spend 1 '
        'Action to throw the Capsule into an unoccupied Square within a '
        "Destructive Sphere AoE (centered on you). If you do, and there's enough "
        'space for the size of the item, it appears instantly in that position '
        'with its central occupied square (if possible – any Square of your '
        'choice, if not) being the Square you threw the Capsule to.',
  ),
  BasicItemDef(
    name: 'Communicator',
    craftDc: 'Apprentice',
    tags: ['Tech'],
    description: 'A long-range communications device enabling real-time '
        'communication across vast distances.',
    effects:
        'With this device, you can communicate with anyone else that has a '
        'Communicator as long as they are within the same galaxy!\n\nAnything '
        'that treats itself as a Communicator can contact Communicators or one '
        'another in the same way.',
  ),
  BasicItemDef(
    name: 'Crystal Ball',
    craftDc: 'Expert',
    description: 'A mystical orb of glass or precious mineral that is purported '
        'to give some people the ability to see into the unknown…',
    effects:
        "A fortune teller's ball that can be made to float with magical "
        'abilities, allowing you to ride upon it or use it to see far away '
        'things. If you possess the Second Sight Unique Ability, you may project '
        'it onto the Crystal Ball so that everyone within your nearby vicinity '
        "can see what you're seeing. If you do not possess the Unique Ability, "
        'you can make an Use Magic Skill Check with a Difficulty Category of '
        'Expert. If you fail, nothing happens. If you pass, you may use the '
        "Second Sight Magical Ability through the Crystal Ball even if you don't "
        'have access to it. Additionally, while holding this item, when making a '
        'Clairvoyance Skill Check, you may use the Skill Bonus of your Use Magic '
        'Skill instead.\n\nIf attempted to be created through Magical '
        'Materialization, the Craft DC for this item is Qualified.',
  ),
  BasicItemDef(
    name: 'Dragon Radar',
    craftDc: 'Master',
    tags: ['Tech'],
    description: 'A radar for finding the notorious Dragon Balls.',
    effects:
        'A portable device that helps you locate Dragon Balls by scanning for '
        'the electromagnetic pulse emitted by them. Notably, the radar gives a '
        "visual representation of depth and height, but it doesn't give actual "
        'values for those metrics. Pressing the button on the top causes the '
        'view to zoom in and show a more detailed map of the area, helping '
        'narrow down the precise location. The radar can locate Dragon Balls at '
        'great distances, such as across a continent, planet, or even the '
        'universe.\n\nYou gain access to the Item Search Adventure Maneuver, but '
        'you can only target a Dragon Ball with its effects.',
  ),
  BasicItemDef(
    name: 'Flash Bang',
    craftDc: 'Qualified',
    tags: ['Tech'],
    description: 'A thrown weapon that blinds and deafens targets.',
    effects:
        'Spend 1 Action to target a Square within a Destructive Sphere AoE '
        '(centered on yourself). Make a Clash (Impulsive) against all Characters '
        'within a Sphere AoE of your targeted Square. If you win, they gain the '
        'Blinded Combat Condition until the start of your next turn.',
  ),
  BasicItemDef(
    name: 'Grenade',
    craftDc: 'Qualified',
    tags: ['Tech'],
    description: 'A hand-held explosive that you lob at an enemy.',
    effects:
        'When you create this Basic Item, record your Scholarship Modifier. When '
        'using the Throw Maneuver, that Attacking Maneuver has a Minor Sphere '
        'AoE (centered on the initial target of this Maneuver) and the Damage '
        'Attribute for that Attacking Maneuver is the Scholarship Modifier '
        'recorded when this Basic Item was created, but this Basic Item is '
        'destroyed after concluding the Maneuver.',
  ),
  BasicItemDef(
    name: 'Key',
    craftDc: 'Qualified',
    description: 'A tool to open a lock, this item is practically a necessity '
        'for any home.',
    effects:
        "When you create this Key, you must target a Base's Door where you are "
        'the Owner, or a Basic Item you created that requires it. This Key only '
        'works on that chosen target.',
  ),
  BasicItemDef(
    name: 'Longevity Supplement',
    craftDc: 'Expert',
    description: 'An aid to health, this item extends your expected lifespan.',
    effects:
        'You can spend 1 Action to consume this item. If you do, stop suffering '
        'from the Fatigued or Stress Exhaustion Combat Conditions. You can only '
        'use this Basic Item once per Combat Encounter.',
  ),
  BasicItemDef(
    name: 'Medicine',
    craftDc: 'Qualified',
    tags: ['Med'],
    description: 'A drug designed to treat your wounds.',
    effects:
        'Spend an Action to consume this Basic Item and regain 2d10(bT) Life '
        'Points. If you were suffering from the Poisoned Combat Condition, '
        'remove that Combat Condition.',
  ),
  BasicItemDef(
    name: 'Net',
    craftDc: 'Expert',
    description: 'A grid of rope created to capture and secure a target.',
    effects:
        'Upon creating this Item, record your Scholarship Modifier, substitute '
        'your Might with this recorded Scholarship Modifier for any Might '
        'Clashes made through the effects of this Basic Item or the Pinned '
        'Combat Condition inflicted through it.\n\nSpend 2 Actions to target a '
        'Character who is not at Long Range. Make a Clash (Energy Strike/Magic '
        'Strike vs Dodge). If you win, reduce their Defense Value by 1(T) until '
        'the end of your next turn and make a Might Clash against that same '
        'Character. If you win, that target is Pinned.',
  ),
  BasicItemDef(
    name: 'Performance Enhancer',
    craftDc: 'Master',
    tags: ['Med'],
    description: 'A powerful medication that improves your athletic prowess.',
    effects:
        'Spend an Action to consume this Basic Item and enter the Doping '
        'Enhancement (even if you do not have access to it).',
  ),
  BasicItemDef(
    name: 'Poison Vial',
    craftDc: 'Expert',
    description: 'A vial containing a deadly poison to use against your enemies.',
    effects:
        'When you create this Basic Item, it has 1d6 Poison Drops. You may spend '
        '1 Action and 1 Poison Drop to Poison a Weapon. A Poisoned Weapon '
        'inflicts the Poisoned Combat Condition to a Character if you knock them '
        'through a Health Threshold with an Attacking Maneuver using that '
        'Weapon.\n\nA Weapon stops being Poisoned at the end of the Combat '
        'Encounter.',
  ),
  BasicItemDef(
    name: 'Remote Control',
    craftDc: 'Expert',
    tags: ['Tech'],
    description: 'A portable device capable of wireless communication with the '
        'advanced computational systems of a Battle Jacket, allowing for remote '
        'operation.',
    effects:
        'Upon creating this Basic Item, select an Item (Bomb/Collar/Vehicle/'
        'Battle Jacket) you possess for it to be connected to. This Remote '
        'Control can be used to control that Item, allowing you to spend your '
        'Actions as if you are Piloting a Vehicle or Battle Jacket that can be '
        'controlled with this Remote Control. For a Bomb, you can spend 1 Action '
        'to trigger that Bomb. For a Collar Accessory, you can spend 1 Action to '
        'trigger the effects of that Accessory.\n\nYou cannot use this effect if '
        'the Vehicle or Battle Jacket has a Pilot.',
  ),
  BasicItemDef(
    name: 'Rice Cooker',
    craftDc: 'Apprentice',
    tags: ['Tech'],
    description: 'An electric pot designed to cook rice to delicious perfection.',
    effects:
        'This item can cook rice. While Adventuring, you can spend 1 Hour and 1 '
        'Ingredient to produce a Snack Basic Item (this is considered an '
        'Adventuring Maneuver with a Session Limit of 1). Additionally, it can '
        'be used as a container for the Sealing Unique Ability. While acting as '
        'a container, it cannot produce the Snack Basic Item through its '
        'effects.',
  ),
  BasicItemDef(
    name: 'Sake Bottle',
    craftDc: 'Qualified',
    tags: ['Food'],
    description: 'A flask, gourd, or other drink container which you can fill '
        'with your choice of drink.',
    effects:
        'When this item is created, it holds 4 stacks of Alcohol and cannot hold '
        'more than 4 stacks of Alcohol. You can spend 1 Action and 1 Alcohol '
        'from the Sake Bottle to enter the Drunk Special State until the start '
        'of your next turn.\n\nYou can refill your Sake Bottle while Adventuring, '
        'but when it has no Alcohol left in it, it can be used for the Sealing '
        'Unique Ability.',
  ),
  BasicItemDef(
    name: 'Scout Scope',
    craftDc: 'Apprentice',
    tags: ['Tech'],
    description: "A handheld device capable of indicating a combatant's "
        'individual combat strength.',
    effects:
        'You can spend 3 Actions to attempt to scan the strength of another '
        'Character. Any Character that is using the Holding Back Maneuver or is '
        'aware of the scanning can make a Qualified Concealment Skill Check. If '
        'they succeed, nothing happens and they automatically succeed on any '
        'further Concealment Skill Checks to avoid being spotted by a Scout '
        'Scope for the remainder of the Combat Encounter. If their number of '
        'Holding Back stacks would decrease below their current number, they '
        'lose this benefit. If they fail, you become aware of their current Tier '
        'of Power. If their current Tier of Power is the same as their base Tier '
        'of Power, you also learn of their Power Level.\n\nWhile you hold this '
        'Basic Item, you have access to the Scan Adventuring Maneuver.',
  ),
  BasicItemDef(
    name: 'Sealing Bottle',
    craftDc: 'Expert',
    description: 'A small, leak-proof bottle designed for long-term storage.',
    effects:
        'A bottle that can be used to hold a small amount of liquid.  '
        'Additionally, it can be used for the Sealing Unique Ability. This Item '
        "doesn't require the Sealing Talisman, but you still must spend 1 Action "
        'to seal the Item.',
  ),
  BasicItemDef(
    name: 'Sealing Talisman',
    craftDc: 'Qualified',
    description: 'A mystical charm crafted to blockade or trap evil spirits.',
    effects:
        'You can spend 1 Action to apply it to a container holding a Character '
        'sealed with the Sealing Unique Ability. If you do so, they are sealed '
        'indefinitely until the seal is removed. The seal can be removed by an '
        'attack with a Called Shot or by spending 1 Action to remove it when '
        'adjacent to the container.\n\nIf attempted to be created through '
        'Magical Materialization, the Craft DC for this item is Apprentice.',
  ),
  BasicItemDef(
    name: 'Smoke Bomb',
    craftDc: 'Apprentice',
    description: 'A mixture of black powder and chemicals set to ignite upon '
        'physical impact, this object creates a thick black cloud of smoke when '
        'used.',
    effects:
        'You may spend 1 Action to throw the Smoke Bomb at any Square within a '
        'Destructive Sphere AoE (centered on you). Create a Destructive Sphere '
        'AoE centered on your chosen Square. In this AoE, all Squares gain the '
        'Obscured Environmental Quality until the end of your next turn.',
  ),
  BasicItemDef(
    name: 'Snack',
    craftDc: 'Apprentice',
    tags: ['Food'],
    description: 'A delicious and satisfying treat to keep you going when your '
        'energy is low.',
    effects:
        'You can spend 1 Action to consume this Item and regain 1d10(bT) Life '
        'and Ki Points. Consuming a Snack will also reduce your Hunger by 1 '
        'until the end of the Combat Encounter.',
  ),
  BasicItemDef(
    name: 'Taser',
    craftDc: 'Qualified',
    tags: ['Tech'],
    description: 'A handheld object that can be used to incapacitate an enemy.',
    effects:
        'You can spend 1 Action while you possess this Item to target a '
        'Character within your Melee Range. Make a Clash (Strike vs '
        'Strike/Dodge). If you win, that Character is knocked Prone until the '
        'start of your next turn. They cannot remove the Prone Combat Condition '
        'inflicted by a Taser until then.\n\nYou can increase the Craft DC to '
        'Expert to increase your Melee Range by 3 when using this Basic Item.',
  ),
  BasicItemDef(
    name: 'Torch',
    craftDc: 'Novice',
    description: 'A handheld light source you can carry with you.',
    effects:
        'You can spend 1 Action to turn on a Torch. While you are holding a '
        'Torch, you are a Light Source. Increase the Light Level of all Squares '
        'within a Sphere AoE (centered on you) by 1 Level.',
  ),
  // --- Special Basic Items --------------------------------------------------
  BasicItemDef(
    name: 'Bag of Senzu Beans',
    craftDc: '',
    isSpecial: true,
    description: 'A bag containing the miraculous Senzu Beans.',
    effects:
        'You can spend 1 Action to consume a Senzu Bean or feed it to an '
        'adjacent, Defeated Character. Consuming a Senzu Bean removes all Combat '
        'Conditions (except Pinned or Suffocating) and you fully regain your '
        'Life and Ki Points, up to their maximum.\n\nBags of Senzu Beans come in '
        "various sizes:\n\nSmall. Roll a 1d4, that's how many Senzu Beans are in "
        "the bag.\n\nStandard. Roll a 1d6, that's how many Senzu Beans are in "
        "the bag.\n\nLarge. Roll a solid 1d10, that's how many Senzu Beans are "
        "in the bag.\n\nExtra Large. Roll a 2d6, that's how many Senzu Beans are "
        'in the bag.',
  ),
  BasicItemDef(
    name: 'Dragon Ball',
    craftDc: '',
    isSpecial: true,
    description: 'One of the magic dragon balls. You can find them all.',
    effects:
        'Dragon Balls come in sets of 2~7 balls. Once you gather all of them, '
        'you may spend all the Actions in your turn (minimum 3) to summon an '
        'Eternal Dragon in a Combat Encounter.',
  ),
  BasicItemDef(
    name: 'Ensenji',
    craftDc: '',
    isSpecial: true,
    description: 'This powerful fruit bears the magical ability to restore you '
        'to full health, making you stronger in the process.',
    effects:
        'You can spend 1 Action to consume this Basic Item. If you do, regain '
        'all of your Life and Ki Points, up to their maximum. Additionally, gain '
        'a stack of the Unlocked Potential Awakening as a Level 1 Temporary '
        'Awakening.',
  ),
  BasicItemDef(
    name: 'Energy-Suction Device',
    craftDc: '',
    isSpecial: true,
    description: 'An item for gathering and storing energy, the utility of this '
        'item cannot be underestimated.',
    effects:
        'While you possess this Item, gain access to the Power Drain Special '
        'Maneuver, but you may use its effects even if you are not in a Grapple. '
        'If you do, you must win a Clash (Physical Strike vs Strike/Dodge) '
        'against your target before using the effects of the Power Drain Special '
        'Maneuver. You do not regain any Ki Points from the Power Drain Special '
        'Maneuver used through this Item, however, but they are instead stored '
        'inside the Energy-Suction Device. You can spend 1 Action to regain any '
        'number of Ki Points that are stored in the Energy-Suction Device or, '
        'when making an Unarmed Energy or Magic Attacking Maneuver, you may '
        'instead spend the Ki Points stored in the Energy-Suction Device.',
  ),
  BasicItemDef(
    name: 'Fruit from the Tree of Might',
    craftDc: '',
    isSpecial: true,
    description: 'A fruit from the legendary Tree of Might; tales tell of this '
        "fruit's ability to make any warrior nigh-unstoppable.",
    effects:
        'You can spend 1 Action to consume this fruit. When you do, completely '
        "restore all of your Ki Points and gain a stack of the Fruit's Might "
        'Awakening as a Level 1 Temporary Awakening.',
  ),
  BasicItemDef(
    name: 'Medibugs',
    craftDc: '',
    isSpecial: true,
    description: 'These bugs have medicinal properties when consumed. Slimy, but '
        'satisfying.',
    effects:
        'Upon gaining this Basic Item, select up to 1d6 Medibugs from the '
        'categories below. You gain those Medibugs. You can spend 1 Action to '
        'consume a Medibug and apply the benefits listed:\n\nRevive Bug. Regain '
        'Life Points and Ki Points up to their maximums.\n\nAchichi Bug. Remove '
        'any stacks of Damage Over Time and/or the Broken Combat '
        'Condition.\n\nZutsu Bug. Remove the Impaired and/or the Impediment '
        'Combat Conditions.\n\nBeaut Bug. Increase your Persuasion Skill Checks '
        'by 2 for an hour.\n\nJoin Bug. You can spend 1 Action to split a Join '
        'Bug in half and give the other half to a Character within a Destructive '
        'Sphere AoE (centered on you). Then, you may spend 1 Action to consume '
        'this half of the Join Bug. If a Character consumes the other half of '
        'that Join Bug, you immediately combine together as an Out-of-Sequence '
        'Maneuver, forming a Fusion on a Square adjacent to one of you through '
        'the Merge Fusion Method.',
  ),
  BasicItemDef(
    name: 'Saibamen Capsule',
    craftDc: '',
    isSpecial: true,
    description: 'A container for seeds, these alien plants grow quickly into '
        'semi-intelligent creatures capable of following basic instructions.',
    effects:
        'When you first gain this Basic Item, roll a 1d8. The Dice Score is the '
        'amount of Saibamen you possess. You can spend 1 Action to plant a '
        'Saibamen Seed. At the start of the next Combat Round, all Saibamen '
        'Seeds planted during this Combat Round will sprout on any Square within '
        '2 Squares of you (you decide) and turn into a number of Saibamen equal '
        'to the number of seeds planted.\n\nSaibamen are Minions made through '
        'the Minion Creation Rules and must select Saibamen as their race.',
  ),
  BasicItemDef(
    name: 'Teleport Remote',
    craftDc: '',
    isSpecial: true,
    description: 'Via this magical device, you are able to teleport yourself '
        'directly to a specific person, or teleport that person to you.',
    effects:
        'Upon gaining this Special Item, a Character is assigned with this. By '
        'spending 1 Action, you may either move to a Square of your choice '
        'adjacent to that Character, or move that Character to a Square of your '
        'choice adjacent to you.',
  ),
  BasicItemDef(
    name: 'Universe Seed',
    craftDc: '',
    isSpecial: true,
    description: 'A potent seed which possesses extraordinary powers great '
        'enough to transcend reality and spawn new universes.',
    effects:
        'This Special Basic Item must be charged by engaging in battle with '
        'powerful beings. Your ARC will decide the level of charge within the '
        'Universe Seed. Once you reach a Partial Charge, you gain access to the '
        'Ultimate Being Legendary Form. Once you reach a Full Charge, you gain '
        'access to the Godslayer Legendary Form.\n\nBy those with the '
        'capabilities, it can also be used for its original purpose once it has '
        'reached a Full Charge: growing a Universal Tree and creating a new '
        'universe…',
  ),
];

/// Looks up a Basic Item by exact [name], or `null` if unknown.
BasicItemDef? basicItemByName(String name) {
  for (final b in kDbuBasicItems) {
    if (b.name == name) return b;
  }
  return null;
}
