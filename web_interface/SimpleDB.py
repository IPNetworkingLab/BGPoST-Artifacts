import shelve
from ipaddress import ip_address
from utils import MY_AS_CONFIG, DB_NAME


class MiniDBMeta(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            instance = super().__call__(*args, **kwargs)
            cls._instances[cls] = instance
        return cls._instances[cls]


class MiniDB(metaclass=MiniDBMeta):
    def __init__(self, db_path: str):
        db = shelve.open(db_path, 'c')
        self._db = db
        if 'auto_tunnel_v6' not in db:
            db['llv6_base_pfx'] = ip_address(MY_AS_CONFIG['base_tunnel_pfx_llv6'])
            db['auto_tunnel_v6'] = MY_AS_CONFIG['auto_tunnel_id']
            db['wg_listen_port'] = MY_AS_CONFIG['wg_listen_port']
            db['wg_prefix_name'] = MY_AS_CONFIG['wg_base_name']
            db['wg_auto_id'] = MY_AS_CONFIG['wg_base_id']

        if 'clients' not in db:
            db['clients'] = {}

        db.sync()
        print(f'DB: \"{db_path}\" is now opened')

    @property
    def db(self) -> shelve.Shelf:
        return self._db

    def contains_client(self, local_ip: str):
        return local_ip in self._db['clients']


def db_get() -> MiniDB:
    return MiniDB(DB_NAME)
