// Tipi minimi del runtime JavaScript di Nakama usati da questo modulo.
// Ricavati dalla documentazione di nakama-common (heroiclabs/nakama-common),
// limitati alle API che chiamiamo.

declare namespace nkruntime {
  interface Context {
    userId?: string;
    username?: string;
    matchId?: string;
    env: { [key: string]: string };
  }

  interface Logger {
    info(format: string, ...params: any[]): void;
    warn(format: string, ...params: any[]): void;
    error(format: string, ...params: any[]): void;
    debug(format: string, ...params: any[]): void;
  }

  interface Presence {
    userId: string;
    sessionId: string;
    username: string;
    node: string;
  }

  interface MatchMessage {
    sender: Presence;
    opCode: number;
    data: ArrayBuffer;
    reliable: boolean;
    receiveTimeMs: number;
  }

  interface MatchDispatcher {
    broadcastMessage(
      opcode: number,
      data?: ArrayBuffer | string | null,
      presences?: Presence[] | null,
      sender?: Presence | null,
      reliable?: boolean,
    ): void;
    matchLabelUpdate(label: string): void;
  }

  interface MatchmakerResult {
    properties: { [key: string]: any };
    presence: Presence;
  }

  interface StorageReadRequest {
    collection: string;
    key: string;
    userId: string;
  }

  interface StorageObject {
    collection: string;
    key: string;
    userId: string;
    value: { [key: string]: any };
    version: string;
  }

  interface StorageWriteRequest {
    collection: string;
    key: string;
    userId: string;
    value: { [key: string]: any };
    permissionRead?: number;
    permissionWrite?: number;
  }

  interface LeaderboardRecord {
    ownerId: string;
    username: string;
    score: number;
    subscore: number;
    rank: number;
  }

  interface LeaderboardRecordList {
    records?: LeaderboardRecord[];
    ownerRecords?: LeaderboardRecord[];
  }

  type SortOrder = 'ascending' | 'descending';
  type Operator = 'best' | 'set' | 'increment' | 'decrement';

  interface Group {
    id: string;
    name: string;
  }

  interface User {
    userId: string;
    username: string;
  }

  interface UserGroupList {
    userGroups?: { group: Group; state: number }[];
  }

  interface GroupUserList {
    groupUsers?: { user: User; state: number }[];
  }

  interface Match {
    matchId: string;
    label: string;
    size: number;
  }

  interface Nakama {
    userGroupsList(userId: string, limit?: number, state?: number | null, cursor?: string): UserGroupList;
    groupUsersList(groupId: string, limit?: number, state?: number | null, cursor?: string): GroupUserList;
    notificationSend(
      userId: string,
      subject: string,
      content: { [key: string]: any },
      code: number,
      senderId?: string | null,
      persistent?: boolean,
    ): void;
    matchList(
      limit?: number,
      authoritative?: boolean | null,
      label?: string | null,
      minSize?: number | null,
      maxSize?: number | null,
      query?: string | null,
    ): Match[];
    matchCreate(module: string, params?: { [key: string]: any }): string;
    storageRead(keys: StorageReadRequest[]): StorageObject[];
    storageWrite(objects: StorageWriteRequest[]): any;
    leaderboardCreate(
      id: string,
      authoritative: boolean,
      sortOrder?: SortOrder,
      operator?: Operator,
      resetSchedule?: string | null,
      metadata?: { [key: string]: any } | null,
    ): void;
    leaderboardRecordWrite(
      id: string,
      ownerId: string,
      username?: string,
      score?: number,
      subscore?: number,
      metadata?: { [key: string]: any } | null,
    ): LeaderboardRecord;
    leaderboardRecordsList(
      id: string,
      ownerIds?: string[] | null,
      limit?: number,
      cursor?: string,
      overrideExpiry?: number,
    ): LeaderboardRecordList;
    stringToBinary(str: string): ArrayBuffer;
    binaryToString(data: ArrayBuffer): string;
  }

  interface MatchState {
    [key: string]: any;
  }

  type MatchInitFunction = (
    ctx: Context, logger: Logger, nk: Nakama, params: { [key: string]: string },
  ) => { state: MatchState; tickRate: number; label: string };

  type MatchJoinAttemptFunction = (
    ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
    tick: number, state: MatchState, presence: Presence,
    metadata: { [key: string]: any },
  ) => { state: MatchState; accept: boolean; rejectMessage?: string } | null;

  type MatchJoinFunction = (
    ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
    tick: number, state: MatchState, presences: Presence[],
  ) => { state: MatchState } | null;

  type MatchLeaveFunction = MatchJoinFunction;

  type MatchLoopFunction = (
    ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
    tick: number, state: MatchState, messages: MatchMessage[],
  ) => { state: MatchState } | null;

  type MatchTerminateFunction = (
    ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
    tick: number, state: MatchState, graceSeconds: number,
  ) => { state: MatchState } | null;

  type MatchSignalFunction = (
    ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
    tick: number, state: MatchState, data: string,
  ) => { state: MatchState; data?: string } | null;

  interface MatchHandler {
    matchInit: MatchInitFunction;
    matchJoinAttempt: MatchJoinAttemptFunction;
    matchJoin: MatchJoinFunction;
    matchLeave: MatchLeaveFunction;
    matchLoop: MatchLoopFunction;
    matchTerminate: MatchTerminateFunction;
    matchSignal: MatchSignalFunction;
  }

  type RpcFunction = (ctx: Context, logger: Logger, nk: Nakama, payload: string) => string | void;

  type MatchmakerMatchedFunction = (
    ctx: Context, logger: Logger, nk: Nakama, matches: MatchmakerResult[],
  ) => string | void;

  interface Initializer {
    registerRpc(id: string, func: RpcFunction): void;
    registerMatch(name: string, functions: MatchHandler): void;
    registerMatchmakerMatched(func: MatchmakerMatchedFunction): void;
  }

  type InitModule = (ctx: Context, logger: Logger, nk: Nakama, initializer: Initializer) => void;
}
