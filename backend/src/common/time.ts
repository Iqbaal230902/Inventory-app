/** Komponen tanggal di zona waktu tertentu (mis. Asia/Jakarta). */
export function zonedParts(date: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const get = (t: string) => parts.find((p) => p.type === t)!.value;
  return {
    year: get('year'),
    month: get('month'),
    day: get('day'),
    hour: get('hour'),
    minute: get('minute'),
  };
}

/** Offset zona waktu (menit) pada saat `date`. */
function offsetMinutes(date: Date, timeZone: string) {
  const p = zonedParts(date, timeZone);
  const asUtc = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute);
  return Math.round(
    (asUtc - Math.floor(date.getTime() / 60000) * 60000) / 60000,
  );
}

/** Awal hari (00:00 lokal) dalam UTC untuk tanggal `date` di zona `timeZone`. */
export function startOfLocalDay(
  date: Date,
  timeZone: string,
  addDays = 0,
): Date {
  const p = zonedParts(date, timeZone);
  const localMidnightAsUtc = Date.UTC(+p.year, +p.month - 1, +p.day + addDays);
  const off = offsetMinutes(new Date(localMidnightAsUtc), timeZone);
  return new Date(localMidnightAsUtc - off * 60000);
}

/** Awal bulan (tgl 1, 00:00 lokal) dalam UTC untuk bulan `date` di zona `timeZone`. */
export function startOfLocalMonth(date: Date, timeZone: string): Date {
  const p = zonedParts(date, timeZone);
  const firstAsUtc = Date.UTC(+p.year, +p.month - 1, 1);
  const off = offsetMinutes(new Date(firstAsUtc), timeZone);
  return new Date(firstAsUtc - off * 60000);
}

export function periodOf(date: Date, timeZone: string) {
  const p = zonedParts(date, timeZone);
  return `${p.year}${p.month}`;
}
