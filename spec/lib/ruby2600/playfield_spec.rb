require 'spec_helper'

describe Ruby2600::Playfield do

  let(:tia) { double 'tia', :reg => Array.new(64, 0), :scanline_stage => :visible }
  subject(:playfield) { Ruby2600::Playfield.new(tia, 0) }

  def scanline
    playfield.reset
    (0..159).map{ playfield.tick; playfield.pixel }
  end

  describe 'pixel' do
    it 'never outputs if COLUP0 is all zeros' do
      tia.reg[COLUP0] = 0
      300.times { expect(playfield.pixel).to be_nil }
    end

    context 'drawing, reflection and score mode' do
      before do
        tia.reg[COLUPF] = 0xFF
        tia.reg[COLUP0] = 0x11
        tia.reg[COLUP1] = 0x22

        tia.reg[PF0] = 0b01000101
        tia.reg[PF1] = 0b01001011
        tia.reg[PF2] = 0b01001011
      end

      it 'generates symmetrical playfield if bit 0 (reflect) is set' do
        tia.reg[CTRLPF] = 0b00000001

        expect(scanline).to eq([nil, nil, nil, nil, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil,
                            nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF, 0xFF, 0xFF, 0xFF, nil, nil, nil, nil, nil, nil, nil, nil])
      end

      it 'uses player colors for playfield if bit 1 is set (score mode)' do
        tia.reg[CTRLPF] = 0b00000010

        expect(scanline).to eq([nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil,
                            nil, nil, nil, nil, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil])
      end

      it 'combines score mode and reflect' do
        tia.reg[CTRLPF] = 0b00000011

        expect(scanline).to eq([nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil, nil, nil, nil, nil, 0x11, 0x11, 0x11, 0x11, nil, nil, nil, nil,
                            nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, nil, nil, nil, nil, 0x22, 0x22, 0x22, 0x22, nil, nil, nil, nil, nil, nil, nil, nil])
      end
    end
  end
end
