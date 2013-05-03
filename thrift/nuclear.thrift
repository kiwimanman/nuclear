namespace rb Nuclear

enum Vote {
  YES = 1,
  NO  = 2,
}

enum Status {
  ABORTED   = 1,
  COMMITED  = 2,
  PENDING   = 3,
  UNCERTAIN = 4
}

service store {
  string    put(1:string key, 2:string value),
  string    get(1:string key),
  string remove(1:string key),
  Status status(1:string transaction_id)
}

service replica {
  oneway void      put(1:string key, 2:string value, 3:string transaction_id),
       string      get(1:string key),
  oneway void   remove(1:string key, 2:string transaction_id),
  oneway void  votereq(1:string transaction_id),
  oneway void finalize(1:string transaction_id, 2:Status decision)
       Status   status(1:string transaction_id)
}

service master {
  oneway void cast_vote(1:string transaction_id, 2:Vote vote),
       Status    status(1:string transaction_id)
}