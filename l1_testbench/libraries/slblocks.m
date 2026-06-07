function blkStruct = slblocks
% Registra l1_blocks en el Library Browser de Simulink
  Browser.Library = 'l1_blocks';
  Browser.Name    = 'L1 Test Bench Blocks';
  blkStruct.Browser = Browser;
end