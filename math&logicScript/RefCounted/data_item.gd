class_name data_item extends RefCounted

var money: int = 999
var money_type: int = 1
var name: String = "???"
var info: String = "??? ???"
var infinity: bool = false

static func from_dict(args: Dictionary) -> data_item:
	if args.size() < 4:
		return
	var d := data_item.new()
	if args.has('money'):
		d.money = args['money']
	elif args.has('m'):
		d.money = args['m']
	if args.has('money_type'):
		d.money_type = args['money_type']
	elif args.has('mt'):
		d.money_type = args['mt']
	if args.has('name'):
		d.name = args['name']
	elif args.has('n'):
		d.name = args['n']
	if args.has('info'):
		d.info = args['info']
	elif args.has('i'):
		d.info = args['i']
	if args.has('infinity'):
		d.infinity = args['infinity']
	return d

static func from_array(args: Array) -> data_item:
	if args.size() < 4:
		return
	var d := data_item.new()
	if args[0] is int:
		d.money = args[0]
	elif args[0] is String:
		d.money = (args[0] as String).to_int()
	if args[1] is int:
		d.money_type = args[1]
	elif args[1] is String:
		d.money_type = (args[1] as String).to_int()
	d.name = str(args[2])
	d.info = str(args[3])
	if args.size() >= 5:
		d.infinity = bool(args[4])
	return d
