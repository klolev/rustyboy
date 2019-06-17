use crate::util::drawer;
use crate::util::drawer::{draw_entity_with_options, DrawnColor, Entity};
use crate::util::wrap_value;
use crate::video::color::ColorFormat;
use crate::video::memory::background_tile_map::BackgroundTileMap;
use crate::video::memory::sprite_attribute_table::OAMEntry;
use crate::video::tile::Tile;
use crate::video::Video;

pub const SCREEN_SIZE: (usize, usize) = (160, 144);
const BACKGROUND_RELATIVE_SIZE: (u8, u8) = (32, 32);
pub const BACKGROUND_SIZE: (usize, usize) = (256, 256);

pub struct Screen {}

impl Screen {
    pub fn draw(video: &Video) -> Vec<u8> {
        Self::draw_with_options(video, ColorFormat::RGB)
    }

    pub fn draw_with_options(video: &Video, format: ColorFormat) -> Vec<u8> {
        let mut buf = vec![DrawnColor::default(); SCREEN_SIZE.0 * SCREEN_SIZE.1];

        if video.control.lcd_enabled() {
            // Background & Window
            if video.control.bg_window_enabled() {
                Self::draw_background_to_buffer(&mut buf, video);

                if video.control.window_enabled() {
                    Self::draw_window_to_buffer(&mut buf, video);
                }
            }

            // Sprites
            Self::draw_sprites_to_buffer(&mut buf, video);
        }

        buf.iter()
            .flat_map(|color| color.color.format(format).to_vec())
            .collect::<Vec<u8>>()
    }

    fn draw_sprites_to_buffer(buffer: &mut Vec<DrawnColor>, video: &Video) {
        let oam_entries = video.vram.oam().entries();
        let tile_data = video.vram.tile_data();
        let tall_sprites = video.control.obj_big_size();

        let sprites: Vec<Sprite> = if video.control.obj_enabled() {
            oam_entries
                .iter()
                .filter(|entry| entry.visible())
                .map(|entry| {
                    let mut tiles = vec![tile_data[entry.tile_number as usize]];
                    if tall_sprites {
                        tiles.push(tile_data[entry.tile_number as usize + 1])
                    }
                    Sprite {
                        tiles,
                        attributes: *entry,
                    }
                })
                .collect()
        } else {
            vec![]
        };

        for sprite in sprites.iter() {
            let entity = Entity::from_sprite(sprite);
            let palette = video.obj_palette(sprite.attributes.obj_palette_number());
            draw_entity_with_options(
                entity,
                SCREEN_SIZE,
                buffer,
                palette,
                true,
                sprite.attributes.behind_bg(),
            )
        }
    }

    fn draw_background_to_buffer(buffer: &mut Vec<DrawnColor>, video: &Video) {
        let (scx, scy) = video.scroll;
        let background_buf = Self::background(video);
        for y in 0..SCREEN_SIZE.1 {
            let background_y = wrap_value(scy as usize + y, BACKGROUND_SIZE.1) as usize;
            for x in 0..SCREEN_SIZE.0 {
                let background_x = wrap_value(scx as usize + x, BACKGROUND_SIZE.0) as usize;
                let idx = y * SCREEN_SIZE.0 + x;
                let background_idx = background_y * BACKGROUND_SIZE.0 + background_x;
                buffer[idx] = background_buf[background_idx];
            }
        }
    }

    pub fn background(video: &Video) -> Vec<DrawnColor> {
        let background_tile_map = if video.control.bg_map() == 0 {
            &video.vram.background_tile_maps().0
        } else {
            &video.vram.background_tile_maps().1
        };

        Self::background_tile_map(video, background_tile_map)
    }

    fn background_tile_map(
        video: &Video,
        background_tile_map: &BackgroundTileMap,
    ) -> Vec<DrawnColor> {
        let tile_data = video.vram.tile_data();
        let mut background_buf =
            vec![DrawnColor::default(); BACKGROUND_SIZE.0 as usize * BACKGROUND_SIZE.1 as usize];
        background_tile_map
            .adjusted_tiles(video.control.bg_tile_data_addressing())
            .iter()
            .map(|tile_index| &tile_data[*tile_index as usize])
            .enumerate()
            .for_each(|(index, tile)| {
                let relative_y = (index - index % BACKGROUND_RELATIVE_SIZE.0 as usize)
                    / BACKGROUND_RELATIVE_SIZE.0 as usize;
                let relative_x = index - relative_y * BACKGROUND_RELATIVE_SIZE.0 as usize;
                let (x, y) = (8 * relative_x, 8 * relative_y);
                let entity = Entity::from_tile(tile, x, y);

                drawer::draw_entity(
                    entity,
                    (BACKGROUND_SIZE.0 as usize, BACKGROUND_SIZE.1 as usize),
                    &mut background_buf,
                    &video.bg_palette,
                );
            });

        background_buf
    }

    fn draw_window_to_buffer(buffer: &mut Vec<DrawnColor>, video: &Video) {
        let (window_x, window_y) = video.window;
        let window_buf = Self::window(video);
        let window_x = window_x.saturating_sub(7);
        for y in 0..BACKGROUND_SIZE.1 {
            let absolute_y = y + window_y as usize;
            if absolute_y >= SCREEN_SIZE.1 {
                break;
            }
            for x in 0..BACKGROUND_SIZE.0 {
                let absolute_x = x + window_x as usize;
                if absolute_x >= SCREEN_SIZE.0 {
                    break;
                }

                let window_idx = y * BACKGROUND_SIZE.0 + x;
                let buffer_idx = absolute_y * SCREEN_SIZE.0 + absolute_x;
                buffer[buffer_idx] = window_buf[window_idx];
            }
        }
    }

    fn window(video: &Video) -> Vec<DrawnColor> {
        let window_tile_map = if video.control.window_bg_map() == 0 {
            &video.vram.background_tile_maps().0
        } else {
            &video.vram.background_tile_maps().1
        };

        Self::background_tile_map(video, window_tile_map)
    }
}

impl Entity {
    pub fn from_sprite(sprite: &Sprite) -> Self {
        Entity {
            width: 8,
            height: sprite.tiles.len() * 8,
            x: (sprite.x() as usize).saturating_sub(8),
            y: (sprite.y() as usize).saturating_sub(16),
            data: sprite
                .tiles
                .iter()
                .flat_map(|tile| {
                    tile.colored_with_options(sprite.x_flipped(), sprite.y_flipped())
                        .to_vec()
                })
                .collect(),
        }
    }

    pub fn from_tile(tile: &Tile, x: usize, y: usize) -> Self {
        Entity {
            width: 8,
            height: 8,
            x,
            y,
            data: tile.colored().to_vec(),
        }
    }
}

#[derive(Debug)]
pub struct Sprite {
    pub tiles: Vec<Tile>,
    pub attributes: OAMEntry,
}

impl Sprite {
    pub fn x(&self) -> u8 {
        self.attributes.position.0
    }

    pub fn y(&self) -> u8 {
        self.attributes.position.1
    }

    pub fn x_flipped(&self) -> bool {
        self.attributes.x_flipped()
    }

    pub fn y_flipped(&self) -> bool {
        self.attributes.y_flipped()
    }
}
