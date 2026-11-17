import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  ValidateNested,
} from 'class-validator';

/** Tonase dikirim sebagai string agar presisi tidak hilang ("15.900" / "15,9"). */
const TON_REGEX = /^\d{1,11}([.,]\d{1,3})?$/;
const TON_MSG = 'harus berupa angka tonase maksimal 3 desimal';

export const INPUT_TRX_TYPES = [
  'IN_RAW',
  'IN_PRODUCTION',
  'IN_SUPPLIER',
  'OUT_SALE',
  'ADJUSTMENT',
] as const;
export type InputTrxType = (typeof INPUT_TRX_TYPES)[number];

export class TrxItemDto {
  @IsInt()
  product_id!: number;

  @IsOptional()
  @IsInt()
  packaging_unit_id?: number;

  @IsOptional()
  @Matches(/^\d{1,10}([.,]\d{1,2})?$/, { message: 'package_qty tidak valid' })
  package_qty?: string;

  /** Opsional jika package_qty diisi — server menghitung dari kemasan. */
  @IsOptional()
  @Matches(TON_REGEX, { message: `qty_ton ${TON_MSG}` })
  qty_ton?: string;

  /**
   * Wajib untuk ADJUSTMENT: 'in' (tambah) atau 'out' (kurang).
   * Untuk produk bersatuan rit (bahan baku mentah), qty_ton berisi jumlah rit.
   */
  @IsOptional()
  @IsIn(['in', 'out'])
  direction?: 'in' | 'out';
}

export class TrxBaseDto {
  @IsOptional()
  @IsInt()
  partner_id?: number;

  @IsOptional()
  @IsString()
  @MaxLength(150)
  partner_name?: string;

  @IsOptional()
  @IsInt()
  vehicle_id?: number;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  plate_number?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  driver_name?: string;

  @IsOptional()
  @Matches(TON_REGEX, { message: `gross_ton ${TON_MSG}` })
  gross_ton?: string;

  @IsOptional()
  @Matches(TON_REGEX, { message: `tare_ton ${TON_MSG}` })
  tare_ton?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  manual_doc_no?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;

  /** Owner saja: izinkan stok negatif dengan alasan. */
  @IsOptional()
  @IsBoolean()
  allow_negative?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  negative_reason?: string;

  /** Konfirmasi tonase di atas batas wajar per truk. */
  @IsOptional()
  @IsBoolean()
  confirm_large?: boolean;
}

export class CreateTransactionDto extends TrxBaseDto {
  @IsUUID('all', { message: 'client_uuid harus UUID.' })
  client_uuid!: string;

  @IsIn(INPUT_TRX_TYPES, { message: 'Jenis transaksi tidak valid.' })
  trx_type!: InputTrxType;

  @IsInt()
  location_id!: number;

  @IsDateString()
  trx_at!: string;

  @IsDateString()
  client_created_at!: string;

  @ValidateNested({ each: true })
  @Type(() => TrxItemDto)
  @ArrayMinSize(1, { message: 'Minimal satu produk.' })
  @ArrayMaxSize(20)
  items!: TrxItemDto[];
}

export class UpdateTransactionDto extends TrxBaseDto {
  @IsOptional()
  @IsDateString()
  trx_at?: string;

  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => TrxItemDto)
  @ArrayMinSize(1, { message: 'Minimal satu produk.' })
  @ArrayMaxSize(20)
  items?: TrxItemDto[];

  @IsString()
  @IsNotEmpty({ message: 'Alasan perubahan wajib diisi.' })
  @MaxLength(255)
  edit_reason!: string;
}

/** Bentuk gabungan yang dipakai PostingService untuk create & update. */
export type TrxBodyDto = TrxBaseDto & { trx_at?: string; items?: TrxItemDto[] };

export class VoidDto {
  @IsString()
  @IsNotEmpty({ message: 'Alasan void wajib diisi.' })
  @MaxLength(255)
  reason!: string;
}

export class ApproveDto {
  @IsOptional()
  @IsString()
  @MaxLength(255)
  note?: string;
}
