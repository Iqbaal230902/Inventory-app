import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';

export type Tx = Prisma.TransactionClient;

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  /**
   * Menjalankan fn dalam satu transaksi database. Deadlock / write conflict
   * (P2034) dicoba ulang beberapa kali karena banyak operator dapat memposting
   * produk yang sama secara bersamaan.
   */
  async withTx<T>(fn: (tx: Tx) => Promise<T>, retries = 5): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.$transaction(fn, {
          maxWait: 10_000,
          timeout: 20_000,
          isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted,
        });
      } catch (e) {
        const retryable =
          e instanceof Prisma.PrismaClientKnownRequestError &&
          (e.code === 'P2034' || /deadlock|lock wait timeout/i.test(e.message));
        const rawDeadlock =
          e instanceof Error && /Deadlock found|1213/.test(e.message);
        if ((retryable || rawDeadlock) && attempt < retries) {
          await new Promise((r) =>
            setTimeout(r, 20 * (attempt + 1) + Math.random() * 40),
          );
          continue;
        }
        throw e;
      }
    }
  }
}
