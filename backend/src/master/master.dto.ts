import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

const TON = /^\d{1,11}([.,]\d{1,3})?$/;

export class ProductDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  @Matches(/^[A-Z0-9_-]+$/i, { message: 'Kode hanya huruf/angka.' })
  code!: string;
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;
  @IsOptional()
  @IsString()
  @MaxLength(20)
  mesh_size?: string | null;
  @IsIn(['raw', 'finished', 'byproduct'])
  category!: 'raw' | 'finished' | 'byproduct';
  @IsOptional()
  @Matches(/^\d{1,3}([.,]\d{1,3})?$/)
  density_ton_m3?: string;
  @IsOptional()
  @IsInt()
  sort_order?: number;
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

export class LocationDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(10)
  @Matches(/^[A-Z0-9]+$/i, { message: 'Kode lokasi hanya huruf/angka.' })
  code!: string;
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;
  @IsIn(['tambang', 'pabrik', 'gudang', 'stockpile'])
  type!: 'tambang' | 'pabrik' | 'gudang' | 'stockpile';
  @IsOptional()
  @IsString()
  @MaxLength(255)
  address?: string | null;
  @IsOptional()
  @IsIn(['Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura'])
  timezone?: string;
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

export class PackagingDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  name!: string;
  @Matches(/^\d{1,7}([.,]\d{1,3})?$/, {
    message: 'Ton per kemasan tidak valid.',
  })
  ton_per_unit!: string;
  @IsOptional()
  @IsBoolean()
  is_bulk?: boolean;
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

export class PartnerDto {
  @IsIn(['customer', 'supplier', 'both'])
  type!: 'customer' | 'supplier' | 'both';
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  name!: string;
  @IsOptional()
  @IsString()
  @MaxLength(30)
  phone?: string | null;
  @IsOptional()
  @IsString()
  @MaxLength(255)
  address?: string | null;
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

export class VehicleDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  plate_number!: string;
  @IsOptional()
  @IsString()
  @MaxLength(100)
  default_driver?: string | null;
  @IsOptional()
  @Matches(TON)
  standard_tare_ton?: string | null;
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

export class MinLevelDto {
  @IsInt()
  location_id!: number;
  @IsInt()
  product_id!: number;
  @Matches(TON, { message: 'Stok minimum tidak valid.' })
  min_ton!: string;
}
