import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';

describe('AppController', () => {
  it('should be defined', async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
    }).compile();
    expect(module.get<AppController>(AppController)).toBeDefined();
  });
});
