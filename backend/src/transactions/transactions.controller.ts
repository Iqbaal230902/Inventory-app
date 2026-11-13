import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { mkdirSync } from 'fs';
import { diskStorage } from 'multer';
import { extname, join, resolve } from 'path';
import { AppError } from '../common/app-error';
import { AuthUser, CurrentUser, Roles } from '../common/auth-user';
import { SettingsService } from '../settings/settings.service';
import { PostingService } from './posting.service';
import {
  ApproveDto,
  CreateTransactionDto,
  UpdateTransactionDto,
  VoidDto,
} from './transaction.dto';
import { serializeTrx } from './transaction.serializer';
import { ListQuery, TransactionsService } from './transactions.service';

export const UPLOAD_DIR = resolve(process.env.UPLOAD_DIR ?? 'uploads');

@Controller('transactions')
export class TransactionsController {
  constructor(
    private posting: PostingService,
    private service: TransactionsService,
    private settings: SettingsService,
  ) {}

  @Get()
  list(@CurrentUser() user: AuthUser, @Query() q: ListQuery) {
    return this.service.list(user, q);
  }

  @Get('plate-check')
  async plateCheck(
    @CurrentUser() user: AuthUser,
    @Query('plate') plate: string,
    @Query('location_id') locationId: string,
  ) {
    const mins = await this.settings.num('duplicate_plate_window_min');
    return this.service.plateCheck(user, plate ?? '', Number(locationId), mins);
  }

  @Get(':id')
  detail(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.service.detail(user, BigInt(id));
  }

  @Post()
  @Roles('owner', 'admin', 'operator')
  async create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateTransactionDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const r = await this.posting.create(user, dto, 'online');
    // DUPLICATE → 200 + hasil lama (PRD 9)
    res.status(r.status === 'duplicate' ? 200 : 201);
    return {
      status: r.status,
      warnings: r.warnings,
      transaction: serializeTrx(r.transaction),
    };
  }

  @Patch(':id')
  @Roles('owner', 'admin')
  async update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateTransactionDto,
  ) {
    return serializeTrx(await this.posting.update(user, BigInt(id), dto));
  }

  @Post(':id/void')
  @Roles('owner', 'admin')
  @HttpCode(200)
  async void(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: VoidDto,
  ) {
    const r = await this.posting.void(user, BigInt(id), dto.reason);
    return { requested: r.requested, transaction: serializeTrx(r.transaction) };
  }

  @Post(':id/approve')
  @Roles('owner', 'admin')
  @HttpCode(200)
  async approve(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ApproveDto,
  ) {
    return serializeTrx(await this.posting.approve(user, BigInt(id), dto.note));
  }

  @Post(':id/print')
  @HttpCode(200)
  print(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body('channel') channel?: string,
  ) {
    return this.service.markPrinted(user, BigInt(id), channel ?? 'unknown');
  }

  @Post(':id/photo')
  @Roles('owner', 'admin', 'operator')
  @HttpCode(200)
  @UseInterceptors(
    FileInterceptor('photo', {
      limits: { fileSize: 600 * 1024 },
      fileFilter: (_req, file, cb) =>
        cb(null, /^image\/(jpeg|png|webp)$/.test(file.mimetype)),
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          const dir = join(UPLOAD_DIR, 'photos');
          mkdirSync(dir, { recursive: true });
          cb(null, dir);
        },
        filename: (req, file, cb) =>
          cb(
            null,
            `trx-${String(req.params.id)}-${Date.now()}${extname(file.originalname) || '.jpg'}`,
          ),
      }),
    }),
  )
  uploadPhoto(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file)
      throw AppError.validation(
        'Foto wajib berupa gambar JPG/PNG maksimal 500 KB.',
      );
    return this.service.setPhoto(user, BigInt(id), `photos/${file.filename}`);
  }

  @Get(':id/photo')
  async photo(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Res() res: Response,
  ) {
    const rel = await this.service.photoPath(user, BigInt(id));
    return res.sendFile(join(UPLOAD_DIR, rel));
  }
}
