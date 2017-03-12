import Foundation	// floor, random, etc

enum Type {
    case bug
    case dark
    case dragon
    case electric
    case fairy
    case fighting
    case fire
    case flying
    case ghost
    case grass
    case ground
    case ice
    case normal
    case poison
    case psychic
    case rock
    case steel
    case water
}

enum Category {
    case physical
    case special
    case status
}

enum Nature {
    case hardy
    case lonely
    case brave
    case adamant
    case naughty
    case bold
    case docile
    case relaxed
    case impish
    case lax
    case timid
    case hasty
    case serious
    case jolly
    case naive
    case modest
    case mild
    case quiet
    case bashful
    case rash
    case calm
    case gentle
    case sassy
    case careful
    case quirky
}

// http://bulbapedia.bulbagarden.net/wiki/Weather
enum Weather {
    case clear_skies
    case harsh_sunlight (extremely: Bool)
    case rain (heavy : Bool)
    case sandstorm
    case hail (diamond_dust : Bool)
    case shadowy_aura
    case fog
    case mysterious_air_current
}

enum Terrain {
    case normal
    case electric
    case grassy
    case psychic
    case misty
}

struct Move : Hashable {
    let id          : Int
    let name        : String
    let description : String
    let category    : Category
    let type        : Type
    let power       : Int
	// let selfStatChange: Stats
	// let foeStatChange: Stats
	// let weatherChange: ?
    let accuracy    : Int
    let powerpoints : Int
    let priority    : Int

    var hashValue   : Int {
      return self.id
    }
}

func ==(lhs: Move, rhs: Move) -> Bool {
    return lhs.id == rhs.id
}

// http://bulbapedia.bulbagarden.net/wiki/Statistic
struct Stats {
    var hitpoints       : Double
    var attack          : Double
    var defense         : Double
    var special_attack  : Double
    var special_defense : Double
    var speed           : Double
}

struct Species : Hashable {
    let id          : Int
    let name        : String
    let evolutions  : Set<Species>
    let attacks     : Set<Move>
    let type        : (Type, Type?)
    let base_values : Stats
    var hashValue   : Int {
      return self.id
    }
}

func ==(lhs: Species, rhs: Species) -> Bool {
    return lhs.id == rhs.id
}

// create kangaskhan species
let species_kangaskhan: Species = Species(
	id: 115,
	name: "Kangaskhan",
	evolutions: [],
	attacks: [move_reversal, move_earthquake, move_iceBeam, move_suckerPunch],
	type: (.normal, nil),
	base_values: Stats(
		hitpoints: 105,
		attack: 95,
		defense: 80,
		special_attack: 40,
		special_defense: 80,
		speed: 90
	)
)

func computeReversalPower(currentHitpoints: Double, maxHitpoints: Double) -> Int {
	// returns damage dealt by the 'reversal' move
	// see http://bulbapedia.bulbagarden.net/wiki/Reversal_(move)
	let HPRatio: Double = currentHitpoints / maxHitpoints

	if (0.0417 > HPRatio) {return 200}
	else if (0.1042 > HPRatio) {return 150}
	else if (0.2083 > HPRatio) {return 100}
	else if (0.3542 > HPRatio) {return 80}
	else if (0.6875 > HPRatio) {return 40}
	else {return 20}
}

let move_reversal: Move = Move(
	id: 179,
	name: "Reversal",
	description: "Stronger if the user's HP is low.",
	category: .physical,
	type: .fighting,
	// fix this so it actually uses the pokemon's hitpoints, whether it is this specific kangaskhan or not
	power: computeReversalPower(currentHitpoints: Double(kangaskhan.current_stats.hitpoints), maxHitpoints: Double(kangaskhan.effective_stats.hitpoints)),	// ?
	accuracy: 100,
	powerpoints: 15,
	priority: 0
)

let move_earthquake: Move = Move(
	id: 89,
	name: "Earthquake",
	description: "Tough but useless vs. flying foes.",
	category: .physical,
	type: .ground,
	power: 100,
	accuracy: 100,
	powerpoints: 10,
	priority: 0
)

let move_iceBeam: Move = Move(
	id: 58,
	name: "Ice Beam",
	description: "An attack that may freeze the foe.",
	category: .special,
	type: .ice,
	power: 90,
	accuracy: 100,
	powerpoints: 10,
	priority: 0
)

let move_suckerPunch: Move = Move(
	id: 389,
	name: "Sucker Punch",
	description: "This move enables the user to attack first. It fails if the foe is not readying an attack, however.",
	category: .physical,
	type: .fighting,
	power: 70,
	accuracy: 100,
	powerpoints: 5,
	priority: 1
)

struct Pokemon {
	let name			  : String
	let nickname          : String?
	let size              : Float
	let weight            : Float
	var experience        : Int	// fix xp/lvl so it's actually calculated
	var level             : Double
	let type			  : (Type, Type?)
	let nature            : Nature
	let species           : Species
	var moves             : [Move] // Move
	var movePowerPoint	  : [Int] // remaining powerpoints
	var statusCondition  : [Int]	// only major ones
	// [burn, freeze, paralysis, (bad)poison, sleep, confusion]
	// 0 if not affected, 1 if affected
	// poison is 1, bad poison is 2
	// for sleep and confusion, the Int is the number of turns that have passed while the condition was active
	let base_values		  : Stats
	let individual_values : Stats
	var effort_values     : Stats
	let effort_values_yield: Stats
	var effective_stats	  : Stats {
		get {
			let stats = computeStats(base_values: base_values, individual_values: individual_values, effort_values: effort_values, level: level)
			return stats
		}
	}
	var current_stats	: Stats
}

func computeStats(base_values: Stats, individual_values: Stats, effort_values: Stats, level: Double) -> Stats {
	//expressions broken up because they're too long for the compiler

	let hitpointsTemp: Double = 2 * base_values.hitpoints + individual_values.hitpoints
	let hitpointsTemp2: Double = hitpointsTemp + floor(effort_values.hitpoints / 4)
	let hitpointsTemp3: Double = floor((hitpointsTemp2 * level)/100)
	let hitpoints: Double = hitpointsTemp3 + level + 10

	let attackTemp: Double = floor(Double(effort_values.attack) / 4)
	let attackTemp2: Double = (2 * base_values.attack + individual_values.attack + attackTemp) * level
	let attackTemp3: Double = floor(attackTemp2 / 100)
	let attack: Double = (attackTemp3 + 5) * 1	// natureMultiplier(attack) instead of '1',

	let defenseTemp: Double = floor(Double(effort_values.defense) / 4)
	let defenseTemp2: Double = (2 * base_values.defense + individual_values.defense + defenseTemp) * level
	let defenseTemp3: Double = floor(defenseTemp2 / 100)
	let defense: Double = (defenseTemp3 + 5) * 1	// natureMultiplier(defense) instead of '1',

	let special_attackTemp: Double = floor(Double(effort_values.special_attack) / 4)
	let special_attackTemp2: Double = (2 * base_values.special_attack + individual_values.special_attack + special_attackTemp) * level
	let special_attackTemp3: Double = floor(special_attackTemp2 / 100)
	let special_attack: Double = (special_attackTemp3 + 5) * 1	// natureMultiplier(special_attack) instead of '1',

	let special_defenseTemp: Double = floor(Double(effort_values.special_defense) / 4)
	let special_defenseTemp2: Double = (2 * base_values.special_defense + individual_values.special_defense + special_defenseTemp) * level
	let special_defenseTemp3: Double = floor(special_defenseTemp2 / 100)
	let special_defense: Double = (special_defenseTemp3 + 5) * 1	// natureMultiplier(special_defense) instead of '1',

	let speedTemp: Double = floor(Double(effort_values.speed) / 4)
	let speedTemp2: Double = (2 * base_values.speed + individual_values.speed + speedTemp) * level
	let speedTemp3: Double = floor(speedTemp2 / 100)
	let speed: Double = (speedTemp3 + 5) * 1	// natureMultiplier(speed) instead of '1',

	return Stats(
		hitpoints: hitpoints,
		attack: attack,
		defense: defense,
		special_attack: special_attack,
		special_defense: special_defense,
		speed: speed)
}

var kangaskhan = Pokemon(
	name: "Kangaskhan",
	nickname: "KANGS",
	size: 2.2,
	weight: 80,
	experience: 1000000, // kangaskhan is a medium-fast leveler, MFXP = lvl^3
	level: 100, // DA VERY BESS
	type : species_kangaskhan.type,
	nature: .hardy,
	species: species_kangaskhan,
	moves: [move_reversal, move_earthquake,	move_iceBeam, move_suckerPunch],
	movePowerPoint: [15,10,10,5],
	statusCondition: [0, 0, 0, 0, 0, 0],
	base_values: species_kangaskhan.base_values,
	individual_values: Stats(
		hitpoints: 31,
		attack: 31,
		defense: 31,
		special_attack: 31,
		special_defense: 31,
		speed: 31),
	effort_values: Stats(
		hitpoints: 200,
		attack: 200,
		defense: 30,
		special_attack: 20,
		special_defense: 30,
		speed: 30),
	effort_values_yield: Stats(	// are we even supposed to account for EV yield?
		hitpoints: 2,
		attack: 0,
		defense: 0,
		special_attack: 0,
		special_defense: 0,
		speed: 0),
	current_stats: Stats(
		hitpoints: 0,
		attack: 0,
		defense: 0,
		special_attack: 0,
		special_defense: 0,
		speed: 0)
)

var kangaskhan2 = Pokemon(
	name: "Kangaskhan",
	nickname: "KANGS2",
	size: 2.2,
	weight: 80,
	experience: 1000000, // kangaskhan is a medium-fast leveler, MFXP = lvl^3
	level: 100, // DA VERY BESS
	type : species_kangaskhan.type,
	nature: .hardy,
	species: species_kangaskhan,
	moves: [move_reversal, move_earthquake,	move_iceBeam, move_suckerPunch],
	movePowerPoint: [15,10,10,5],
	statusCondition: [0, 0, 0, 0, 0, 0],
	base_values: species_kangaskhan.base_values,
	individual_values: Stats(
		hitpoints: 31,
		attack: 31,
		defense: 31,
		special_attack: 31,
		special_defense: 31,
		speed: 31),
	effort_values: Stats(
		hitpoints: 200,
		attack: 200,
		defense: 30,
		special_attack: 20,
		special_defense: 30,
		speed: 30),
	effort_values_yield: Stats(	// are we even supposed to account for EV yield?
		hitpoints: 2,
		attack: 0,
		defense: 0,
		special_attack: 0,
		special_defense: 0,
		speed: 0),
	current_stats: Stats(
		hitpoints: 0,
		attack: 0,
		defense: 0,
		special_attack: 0,
		special_defense: 0,
		speed: 0)
)

struct Item {
	let id: Int
	let name: String
	let description: String
	var amount: Int
	let price: Int
}

struct Trainer {
	let name: String
    var party : [Pokemon]
	var bag: [Item]
}

func ==(lhs: Trainer, rhs: Trainer) -> Bool {
    return lhs.name == rhs.name
}

let trainerA: Trainer = Trainer(
	name: "Trainer A",
	party: [kangaskhan],
	bag: []
)

let trainerB : Trainer = Trainer(	// maybe add some other pokemon
	name: "Trainer B",
	party: [kangaskhan2],
	bag: []
)

var trainers: [Trainer] = [trainerA, trainerB]

struct Environment {
    var weather : Weather
    let terrain : Terrain
}

func typeToInt(type: Type) -> Int {
	//uses standard ordering
	switch type {
		case .normal: return 0
		case .fighting: return 1
		case .flying: return 2
		case .poison: return 3
		case .ground: return 4
		case .rock: return 5
		case .bug: return 6
		case .ghost: return 7
		case .steel: return 8
		case .fire: return 9
		case .water: return 10
		case .grass: return 11
		case .electric: return 12
		case .psychic: return 13
		case .ice: return 14
		case .dragon: return 15
		case .dark: return 16
		case .fairy: return 17
	}
}

func typeModifier(attacking: Type, defending : Type)-> Double {
	let attackingID: Int = typeToInt(type: attacking)
	let defendingID: Int = typeToInt(type: defending)

	let multiplierMatrix: [[Double]] = [
		[  1,  1,  1,  1,  1,0.5,  1,  0,0.5,  1,  1,  1,  1,  1,  1,  1,  1,  1], // normal
		[  2,  1,0.5,0.5,  1,  2,0.5,  0,  2,  1,  1,  1,  1,0.5,  2,  1,  2,0.5], // fighting
		[  1,  2,  1,  1,  1,0.5,  2,  1,0.5,  1,  1,  2,0.5,  1,  1,  1,  1,  1], // flying
		[  1,  1,  1,0.5,0.5,0.5,  1,0.5,  0,  1,  1,  2,  1,  1,  1,  1,  1,  2], // poison
		[  1,  1,  0,  2,  1,  2,0.5,  1,  2,  2,  1,0.5,  2,  1,  1,  1,  1,  1], // ground
		[  1,0.5,  2,  1,0.5,  1,  2,  1,0.5,  2,  1,  1,  1,  1,  2,  1,  1,  1], // rock
		[  1,0.5,0.5,0.5,  1,  1,  1,0.5,0.5,0.5,  1,  2,  1,  2,  1,  1,  2,0.5], // bug
		[  0,  1,  1,  1,  1,  1,  1,  2,  1,  1,  1,  1,  1,  2,  1,  1,0.5,  1], // ghost
		[  1,  1,  1,  1,  1,  2,  1,  1,0.5,0.5,0.5,  1,0.5,  1,  2,  1,  1,  2], // steel
		[  1,  1,  1,  1,  1,0.5,  2,  1,  2,0.5,0.5,  2,  1,  1,  2,0.5,  1,  1], // fire
		[  1,  1,  1,  1,  2,  2,  1,  1,  1,  2,0.5,0.5,  1,  1,  1,0.5,  1,  1], // water
		[  1,  1,0.5,0.5,  2,  2,0.5,  1,0.5,0.5,  2,0.5,  1,  1,  1,0.5,  1,  1], // grass
		[  1,  1,  2,  1,  0,  1,  1,  1,  1,  1,  2,0.5,0.5,  1,  1,0.5,  1,  1], // electric
		[  1,  2,  1,  2,  1,  1,  1,  1,0.5,  1,  1,  1,  1,0.5,  1,  1,  0,  1], // psychic
		[  1,  1,  2,  1,  2,  1,  1,  1,0.5,0.5,0.5,  2,  1,  1,0.5,  2,  1,  1], // ice
		[  1,  1,  1,  1,  1,  1,  1,  1,0.5,  1,  1,  1,  1,  1,  1,  2,  1,  0], // dragon
		[  1,0.5,  1,  1,  1,  1,  1,  2,  1,  1,  1,  1,  1,  2,  1,  1,0.5,0.5], // dark
		[  1,  2,  1,0.5,  1,  1,  1,  1,0.5,0.5,  1,  1,  1,  1,  1,  2,  2,  1]  // fairy
	]

	return (multiplierMatrix[attackingID][defendingID])
}

// http://bulbapedia.bulbagarden.net/wiki/Nature
// let natureMultiplier: [Nature: Stats](
//
//)




// http://bulbapedia.bulbagarden.net/wiki/Damage
// add environment effect
func damage(pokemon: Pokemon, move: Move, target: Pokemon) -> Double {

	var STAB : Double = 1 // initialise with non-STAB multiplier value
	if ( (pokemon.type.0 == move.type) || (pokemon.type.1 == move.type) ) {STAB = 1.5}

	var typeBonus: Double = typeModifier(attacking: move.type, defending: target.type.0)
	if (pokemon.type.1 != nil)
		{ typeBonus *= typeModifier(attacking: move.type, defending: target.type.1!) }
	if (typeBonus == 0)
		{ print("It doesn't affect", target, "...") }
	else if ((typeBonus == 0.25) || (typeBonus == 0.5))
		{ print("It's not very effective...") }
	else if ((typeBonus == 2) || (typeBonus == 4))
		{ print("It's super effective!") }

	var critical: Double = 1 // initialise with non-crit mult value
	let randNum: Int = Int(drand48() * 257) // random int between 0 and 256 (included)
	let threshold: Int = Int(round(pokemon.base_values.speed / 2))
	if ( randNum < threshold)
		{critical = ( (2 * pokemon.level + 5) / (pokemon.level + 5) ) }

	let environmentBonus: Double = 1 // actually calculate this

	let randFactor: Double = ((drand48() * 0.15) + 0.85)	// uniformly distributed between 0.85 and 1

	let others: Double = 1 // actually calculate this. burn, items, etc.

	let modifier : Double = STAB * typeBonus * critical * environmentBonus * randFactor * others

	let tempDamage: Double = (2 * pokemon.level + 10) / 250
	let attDefRatio: Double
	if (move.category == .physical) { attDefRatio = pokemon.effective_stats.attack / target.effective_stats.defense }
	else if (move.category == .special) { attDefRatio = pokemon.effective_stats.special_attack / target.effective_stats.special_defense }
	else { attDefRatio = 0 } // stat-only; 0 damage as safety
	let damage : Double = (tempDamage * attDefRatio * Double(move.power) * 2) * modifier
    return damage
}



func battle(trainers: inout [Trainer]) -> () {

	print("intro blah blah goes here")

	var partyA: [Pokemon]? = trainers[0].party	// player
	var partyB: [Pokemon]? = trainers[1].party	// pc
	let partyASize: Int = partyA!.count
	let partyBSize: Int = partyB!.count
	var partyAFainted: Int = 0
	var partyBFainted: Int = 0


	for _ in partyA! {	// sets pokemon stats to their "default" level (all pokemon, for both trainers)
		partyA![0].current_stats = partyA![0].effective_stats
	}
	for _ in partyB! {
		partyB![0].current_stats = partyB![0].effective_stats
	}

	// TODO: check nicknames, if they exist use them instead of standard names
	print("trainer A sent out", partyA![0].nickname as Any, "trainer B sent out", partyB![0].nickname as Any)

	while ( (partyASize != partyAFainted) && (partyBSize != partyBFainted) ) {

		// TODO: get environment info, print if non-default

		/*
		print("what to do? [F]ight, [B]ag, [P]okemon")	//pick player move
		var playerMove = readLine()

		if ( playerMove == "F" || playerMove == "f" || playerMove == "Fight" || playerMove == "fight" ) {
			// if sum of PP = 0
				// struggle
			// else
				// print index (1-4), move names, descriptions, power, accuracy, PP
				// ask for user input
				// check move has PP left
					// damage + effects
		}
		else if ( playerMove == "B" || playerMove == "b" || playerMove == "Bag" || playerMove == "bag" ) {
			// print contents of bag with an index
			// tell player to choose the index of the item

		}
		else if ( playerMove == "P" || playerMove == "p" || playerMove == "Pokemon" || playerMove == "pokemon" ) {
			// print pokemon, their level, HP, and status condition
			// ask for user input, pick a pokemon
			//check that pokemon isn't Ko before sending it out
		}
		else {
			//...
		}
		*/

		// get moves
		// the "move" is just randomly chosen between the known moves, eventually expand this to allow for user input and to change pokemon and use items
		let moveAIndex: Int = Int(drand48()*5) // assumes a pokemon knows four moves; fix this to get real move count
		let moveBIndex: Int = Int(drand48()*5)
		let moveA: Move = partyA![0].moves[moveAIndex]
		let moveB: Move = partyB![0].moves[moveBIndex]

		// TODO: check PPs!
		// TODO: print("A's pokemon used", moveA), etc.


		// compute move order for the current turn
		// priority: non-damaging
		//				higher move priority
		//					higher pokemon speed
		let firstToMove: Trainer
		if ( (moveA.power == 0) || (moveB.power != 0) )
			{firstToMove =  trainerA}
		else if ( (moveA.power != 0) || (moveB.power == 0) )
			{firstToMove =  trainerB}
		else {
			if (moveA.priority > moveB.priority)
				{firstToMove =  trainerA}
			else if (moveA.priority < moveB.priority)
				{firstToMove =  trainerB}
			else {
				if (partyA![0].effective_stats.speed > partyB![0].effective_stats.speed)
					{firstToMove =  trainerA}
				else if (partyA![0].effective_stats.speed < partyB![0].effective_stats.speed)
					{firstToMove =  trainerB}
				else {	//same speed and priority -> random order
					if (drand48() > 0.5)
						{firstToMove =  trainerA}
					else
						{firstToMove =  trainerA}
				}
			}

		// TODO: check if move changes weather, act accordingly
		// TODO: check if move changes stats, act accordingly

		// first deals damage to second
		let first: Int; let second: Int
		if firstToMove == trainerA { first = 0; second = 1 }
		else { first = 1; second = 0 }

		var attacker = first; var defender = second

		for index in (0...1) { // loops twice, once per pokemon attack
			if trainers[defender].party[0].current_stats.hitpoints >= 0 { //skips second half of turn if second pokemon got KO'd by first
				if (index == 1) {	// if second half of turn, swaps attacker and defender
					var swap: Int
					swap = defender
					defender = attacker
					attacker = swap
				}

				let damageDone = damage(pokemon: trainers[attacker].party[0], move: moveA, target: trainers[defender].party[0])
				trainers[defender].party[0].current_stats.hitpoints -=  damageDone
				print(trainers[defender].party[0], "HP:", trainers[defender].party[0].current_stats.hitpoints, "/", trainers[defender].party[0].effective_stats.hitpoints)
				// TODO: recoil
				if (trainers[1].party[0].current_stats.hitpoints <= 0) {
					print(trainers[1].name, "'s ", trainers[1].party[0], "fainted!")
					partyBFainted += 1
					// change pokemon
				if (trainers[0].party[0].current_stats.hitpoints <= 0) {
					print(trainers[0].name, "'s ", trainers[0].party[0], "fainted!")
					partyAFainted += 1
					// change pokemon
					}
				}
			}
		}

//


		// first to move
			// check status conditions, see if move can be executed (can always switch pokemon)
				// move changes weather?
					// y: set new weather
				// move changes pokemon stats?
					// y, first: set new first stats (self)
					// y, second: set new second stats
				// move deals damage?
					// calculate hit probability
						// calculate damage
						// deal damage to second
						// second (foe) KO?
							// y: opponent tries sending out another pokemon
							// n: move has status effects on second?	// check the order of these
								//y: apply status effects
						// deal recoil damage to first (self) if appropriate
							// self KO?
								// y: first tries sending out another pokemon
		// second KO? n:
			// check status conditions, see if move can be executed (can always switch pokemon)
				// move changes weather?
					// y: set new weather
				// move changes pokemon stats?
					// y, second: set new first stats (self)
					// y, first: set new second stats
				// move deals damage?
					// calculate hit probability
						// calculate damage
						// deal damage to first
						// first (foe) KO?
							// y: opponent tries sending out another pokemon
							// n: move has status effects on first?
								//y: apply status effects
						// deal recoil damage to second (self) if appropriate
							// self KO?
								// y: second tries sending out another pokemon
		// nonzero status conditions on either pokemon: apply effects
			// KO? try sending out another pokemon
		}
	}
}
