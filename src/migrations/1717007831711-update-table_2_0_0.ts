import { MigrationInterface, QueryRunner } from 'typeorm'

export class UpdateTable2001717007831711 implements MigrationInterface {
  name = 'UpdateTable2001717007831711'

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "sys_dept" ADD "create_by" integer`)
    await queryRunner.query(`COMMENT ON COLUMN "sys_dept"."create_by" IS '创建者'`)
    await queryRunner.query(`ALTER TABLE "sys_dept" ADD "update_by" integer`)
    await queryRunner.query(`COMMENT ON COLUMN "sys_dept"."update_by" IS '更新者'`)
    await queryRunner.query(`ALTER TABLE "sys_menu" ADD "create_by" integer`)
    await queryRunner.query(`COMMENT ON COLUMN "sys_menu"."create_by" IS '创建者'`)
    await queryRunner.query(`ALTER TABLE "sys_menu" ADD "update_by" integer`)
    await queryRunner.query(`COMMENT ON COLUMN "sys_menu"."update_by" IS '更新者'`)
    await queryRunner.query(`ALTER TABLE "sys_role" ADD "create_by" integer`)
    await queryRunner.query(`COMMENT ON COLUMN "sys_role"."create_by" IS '创建者'`)
    await queryRunner.query(`ALTER TABLE "sys_role" ADD "update_by" integer`)
    await queryRunner.query(`COMMENT ON COLUMN "sys_role"."update_by" IS '更新者'`)
    await queryRunner.query(`ALTER TABLE "sys_role" ALTER COLUMN "value" SET NOT NULL`)
    await queryRunner.query(`COMMENT ON COLUMN "sys_role"."value" IS '角色标识'`)
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "sys_role" ALTER COLUMN "value" DROP NOT NULL`)
    await queryRunner.query(`ALTER TABLE "sys_role" DROP COLUMN "update_by"`)
    await queryRunner.query(`ALTER TABLE "sys_role" DROP COLUMN "create_by"`)
    await queryRunner.query(`ALTER TABLE "sys_menu" DROP COLUMN "update_by"`)
    await queryRunner.query(`ALTER TABLE "sys_menu" DROP COLUMN "create_by"`)
    await queryRunner.query(`ALTER TABLE "sys_dept" DROP COLUMN "update_by"`)
    await queryRunner.query(`ALTER TABLE "sys_dept" DROP COLUMN "create_by"`)
  }
}
