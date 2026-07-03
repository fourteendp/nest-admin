import {
  BaseEntity,
  BeforeInsert,
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm'

import { UserEntity } from '~/modules/user/user.entity'

import { RefreshTokenEntity } from './refresh-token.entity'
import { generateUUID } from '~/utils'

@Entity('user_access_tokens')
export class AccessTokenEntity extends BaseEntity {
  @BeforeInsert()
  beforeInsert() {
    this.id = generateUUID()
  }

  @PrimaryGeneratedColumn('uuid')
  id!: string

  @Column({ length: 500, default: '' })
  value!: string

  @Column({ comment: '令牌过期时间', nullable: true })
  expired_at!: Date

  @CreateDateColumn({ comment: '令牌创建时间' })
  created_at!: Date

  @OneToOne(() => RefreshTokenEntity, (refreshToken) => refreshToken.accessToken, {
    cascade: true,
  })
  refreshToken!: RefreshTokenEntity

  @ManyToOne(() => UserEntity, (user) => user.accessTokens, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity
}
