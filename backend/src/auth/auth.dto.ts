import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class LoginDto {
  @IsString()
  @IsNotEmpty({ message: 'Username wajib diisi.' })
  username!: string;

  @IsString()
  @IsNotEmpty({ message: 'Password wajib diisi.' })
  password!: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  device_id?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  app_version?: string;
}

export class RefreshDto {
  @IsString()
  @IsNotEmpty()
  refresh_token!: string;
}
