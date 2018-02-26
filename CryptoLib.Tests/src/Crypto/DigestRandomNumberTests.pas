{ *********************************************************************************** }
{ *                              CryptoLib Library                                  * }
{ *                    Copyright (c) 2018 Ugochukwu Mmaduekwe                       * }
{ *                 Github Repository <https://github.com/Xor-el>                   * }

{ *  Distributed under the MIT software license, see the accompanying file LICENSE  * }
{ *          or visit http://www.opensource.org/licenses/mit-license.php.           * }

{ *                              Acknowledgements:                                  * }
{ *                                                                                 * }
{ *        Thanks to Sphere 10 Software (http://sphere10.com) for sponsoring        * }
{ *                        the development of this library                          * }

{ * ******************************************************************************* * }

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)

unit DigestRandomNumberTests;

interface

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF FPC}
{$HINTS OFF}

uses
  Classes,
  SysUtils,
{$IFDEF FPC}
  fpcunit,
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF FPC}
  HlpIHash,
  HlpHashFactory,
  ClpHex,
  ClpArrayUtils,
  ClpDigestRandomGenerator,
  ClpIDigestRandomGenerator,
  ClpCryptoLibTypes;

type

  TCryptoLibTestCase = class abstract(TTestCase)

  end;

type

  TTestDigestRandomNumber = class(TCryptoLibTestCase)
  private

  var
    FZERO_SEED, FTEST_SEED, Fexpected0SHA1, FnoCycle0SHA1, Fexpected0SHA256,
      FnoCycle0SHA256, Fexpected100SHA1, Fexpected100SHA256, FexpectedTestSHA1,
      FexpectedTestSHA256, Fsha1Xors, Fsha256Xors: TBytes;

    procedure doExpectedTest(digest: IHash; seed: Int32;
      expected: TBytes); overload;
    procedure doExpectedTest(digest: IHash; seed, expected: TBytes); overload;
    procedure doExpectedTest(digest: IHash; seed: Int32;
      expected, noCycle: TBytes); overload;
    procedure doCountTest(digest: IHash; seed, expectedXors: TBytes);

  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestDigestRandomNumber;

  end;

implementation

{ TTestDigestRandomNumber }

procedure TTestDigestRandomNumber.doCountTest(digest: IHash;
  seed, expectedXors: TBytes);
var
  rGen: IDigestRandomGenerator;
  output, ands, xors, ors: TBytes;
  averages: TCryptoLibInt32Array;
  i, j: Int32;
begin
  digest.Initialize;
  rGen := TDigestRandomGenerator.Create(digest);
  System.SetLength(output, digest.HashSize);
  System.SetLength(averages, digest.HashSize);
  System.SetLength(ands, digest.HashSize);
  System.SetLength(xors, digest.HashSize);
  System.SetLength(ors, digest.HashSize);

  rGen.AddSeedMaterial(seed);

  i := 0;

  while i <> 1000000 do
  begin
    rGen.NextBytes(output);
    j := 0;
    while j <> System.Length(output) do
    begin
      averages[j] := averages[j] + (output[j] and $FF);
      ands[j] := ands[j] and output[j];
      xors[j] := xors[j] xor output[j];
      ors[j] := ors[j] or output[j];
      System.Inc(j);
    end;
    System.Inc(i);
  end;

  i := 0;
  while i <> System.Length(output) do
  begin
    if ((averages[i] div 1000000) <> 127) then
    begin
      Fail(Format('average test failed for %s', [digest.Name]));
    end;
    if (ands[i] <> 0) then
    begin
      Fail(Format('and test failed for %s', [digest.Name]));
    end;
    if ((ors[i] and $FF) <> $FF) then
    begin
      Fail(Format('or test failed for %s', [digest.Name]));
    end;
    if (xors[i] <> expectedXors[i]) then
    begin
      Fail(Format('xor test failed for %s', [digest.Name]));
    end;
    System.Inc(i);
  end;

end;

procedure TTestDigestRandomNumber.doExpectedTest(digest: IHash; seed: Int32;
  expected: TBytes);
begin
  doExpectedTest(digest, seed, expected, Nil);
end;

procedure TTestDigestRandomNumber.doExpectedTest(digest: IHash; seed: Int32;
  expected, noCycle: TBytes);
var
  rGen: IDigestRandomGenerator;
  output: TBytes;
  i: Int32;
begin
  digest.Initialize;
  rGen := TDigestRandomGenerator.Create(digest);
  System.SetLength(output, digest.HashSize);

  rGen.AddSeedMaterial(seed);

  i := 0;

  while i <> 1024 do
  begin
    rGen.NextBytes(output);
    System.Inc(i);
  end;

  if (noCycle <> Nil) then
  begin
    if (TArrayUtils.AreEqual(noCycle, output)) then
    begin
      Fail('seed not being cycled!');
    end;
  end;

  if (not TArrayUtils.AreEqual(expected, output)) then
  begin
    Fail('expected output doesn''t match');
  end;
end;

procedure TTestDigestRandomNumber.doExpectedTest(digest: IHash;
  seed, expected: TBytes);
var
  rGen: IDigestRandomGenerator;
  output: TBytes;
  i: Int32;
begin
  digest.Initialize;
  rGen := TDigestRandomGenerator.Create(digest);
  System.SetLength(output, digest.HashSize);

  rGen.AddSeedMaterial(seed);

  i := 0;

  while i <> 1024 do
  begin
    rGen.NextBytes(output);
    System.Inc(i);
  end;

  if (not TArrayUtils.AreEqual(expected, output)) then
  begin
    Fail('expected output doesn''t match');
  end;
end;

procedure TTestDigestRandomNumber.SetUp;
begin
  FZERO_SEED := TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0);

  FTEST_SEED := THex.Decode('81dcfafc885914057876');

  Fexpected0SHA1 := THex.Decode('95bca677b3d4ff793213c00892d2356ec729ee02');
  FnoCycle0SHA1 := THex.Decode('d57ccd0eb12c3938d59226412bc1268037b6b846');
  Fexpected0SHA256 :=
    THex.Decode
    ('587e2dfd597d086e47ddcd343eac983a5c913bef8c6a1a560a5c1bc3a74b0991');
  FnoCycle0SHA256 := THex.Decode
    ('e5776c4483486ba7be081f4e1b9dafbab25c8fae290fd5474c1ceda2c16f9509');
  Fexpected100SHA1 := THex.Decode('b9d924092546e0876cafd4937d7364ebf9efa4be');
  Fexpected100SHA256 :=
    THex.Decode
    ('fbc4aa54b948b99de104c44563a552899d718bb75d1941cc62a2444b0506abaf');
  FexpectedTestSHA1 := THex.Decode('e9ecef9f5306daf1ac51a89a211a64cb24415649');
  FexpectedTestSHA256 :=
    THex.Decode
    ('bdab3ca831b472a2fa09bd1bade541ef16c96640a91fcec553679a136061de98');

  Fsha1Xors := THex.Decode('7edcc1216934f3891b03ffa65821611a3e2b1f79');
  Fsha256Xors := THex.Decode
    ('5ec48189cc0aa71e79c707bc3c33ffd47bbba368a83d6cfebf3cd3969d7f3eed');
end;

procedure TTestDigestRandomNumber.TearDown;
begin
  inherited;

end;

procedure TTestDigestRandomNumber.TestDigestRandomNumber;
begin
  doExpectedTest(THashFactory.TCrypto.CreateSHA1(), 0, Fexpected0SHA1,
    FnoCycle0SHA1);
  doExpectedTest(THashFactory.TCrypto.CreateSHA2_256(), 0, Fexpected0SHA256,
    FnoCycle0SHA256);

  doExpectedTest(THashFactory.TCrypto.CreateSHA1(), 100, Fexpected100SHA1);
  doExpectedTest(THashFactory.TCrypto.CreateSHA2_256(), 100,
    Fexpected100SHA256);

  doExpectedTest(THashFactory.TCrypto.CreateSHA1(), FZERO_SEED, Fexpected0SHA1);
  doExpectedTest(THashFactory.TCrypto.CreateSHA2_256(), FZERO_SEED,
    Fexpected0SHA256);

  doExpectedTest(THashFactory.TCrypto.CreateSHA1(), FTEST_SEED,
    FexpectedTestSHA1);
  doExpectedTest(THashFactory.TCrypto.CreateSHA2_256(), FTEST_SEED,
    FexpectedTestSHA256);

  doCountTest(THashFactory.TCrypto.CreateSHA1(), FTEST_SEED, Fsha1Xors);
  doCountTest(THashFactory.TCrypto.CreateSHA2_256(), FTEST_SEED, Fsha256Xors);
end;

initialization

// Register any test cases with the test runner

{$IFDEF FPC}
  RegisterTest(TTestDigestRandomNumber);
{$ELSE}
  RegisterTest(TTestDigestRandomNumber.Suite);
{$ENDIF FPC}

end.
