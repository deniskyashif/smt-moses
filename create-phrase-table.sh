corpus_name="$1"
source_lang=${2:-"de"}
target_lang=${3:-"en"}

out_dir="/datadrive/nlp/output"
mosesdecoder_path="/datadrive/mosesdecoder"
lm_path="/datadrive/nlp/lm/dummy.arpa"

clean_corpus_n_perl=$mosesdecoder_path/scripts/training/clean-corpus-n.perl
tokenize_perl=$mosesdecoder_path/scripts/tokenizer/tokenizer.perl
train_truecaser_perl=$mosesdecoder_path/scripts/recaser/train-truecaser.perl
truecase_perl=$mosesdecoder_path/scripts/recaser/truecase.perl
detruecase_perl=$mosesdecoder_path/scripts/recaser/detruecase.perl
train_model_perl=$mosesdecoder_path/scripts/training/train-model.perl

mkdir $out_dir

echo "Cleaning..."
$clean_corpus_n $corpus_name \
                $source_lang $target_lang $out_dir/corpus.clean 1 50

echo "Tokenizing..."
$tokenizer -l $source_lang -threads 10 \
           < $out_dir/corpus.clean.$source_lang \
           > $out_dir/corpus.clean.tok.$source_lang

$tokenizer -l $target_lang -threads 10 \
           < $out_dir/corpus.clean.$target_lang \
           > $out_dir/corpus.clean.tok.$target_lang

# IF case sensitive model
echo "Train Truecaser..."
$train_truecaser --model $out_dir/truecase-model.$source_lang \
                 --corpus $out_dir/corpus.clean.tok.$source_lang

$train_truecaser --model $out_dir/truecase-model.$target_lang \
                 --corpus $out_dir/corpus.clean.tok.$target_lang

echo "Truecase..."
$truecase --model $out_dir/truecase-model.$source_lang \
          < $out_dir/corpus.clean.tok.$source_lang \
          > $out_dir/corpus.clean.tok.truecase.$source_lang

$truecase --model $out_dir/truecase-model.$target_lang \
          < $out_dir/corpus.clean.tok.$target_lang \
          > $out_dir/corpus.clean.tok.truecase.$target_lang

# ENDIF case sensitive model

# IF lowercase model
# echo "Train Recaser..."
# $mosesdecoder_path/scripts/recaser/train-recaser.perl --first-step 2 \
#                                                   --dir $out_dir/recaser-$source_lang/ \
#                                                   --corpus $out_dir/corpus.clean.tok.$source_lang

# $mosesdecoder_path/scripts/recaser/train-recaser.perl --first-step 2 \
#                                                   --dir $out_dir/recaser-$target_lang/ \
#                                                   --corpus $out_dir/corpus.clean.tok.$target_lang

# echo "Lowercase..."
# $mosesdecoder_path/scripts/tokenizer/lowercase.perl 
#          < $out_dir/corpus.clean.tok.$source_lang \
#          > $out_dir/corpus.clean.tok.lower.$source_lang

# $mosesdecoder_path/scripts/tokenizer/lowercase.perl < $out_dir/corpus.clean.tok.$target_lang \
#                                                     > $out_dir/corpus.clean.tok.lower.$target_lang
# ENDIF lowercase model

echo "Train Model..."
$train_model -root-dir $out_dir/train/ \
             -external-bin-dir $mosesdecoder_path/tools/bin/ --mgiza --parallel \
             --corpus $out_dir/corpus.clean.tok \
             --f $source_lang --e $target_lang \
             -lm 0:3:$lm_path:8

echo "Binarize the Phrase Table..."                                                 
$mosesdecoderpath/bin/CreateOnDiskPt 1 1 4 100 2 $out_dir/train/model/phrase-table.gz phrase-table-bin-folder

echo "Create Compact Phrase Table..."                                                 
$mosesdecoderpath/bin/processPhraseTableMin -in phrase-table.gz -out phrase-table-compact -nscores 4 -threads 16

echo "Done."
